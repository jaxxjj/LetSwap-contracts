// SPDX-License-Identifier: MIT

pragma solidity 0.8.20;

import {ILetSwapPair} from "./interfaces/ILetSwapPair.sol";
import {LetSwapERC20} from "./LetSwapERC20.sol";
import {Math} from "./libraries/Math.sol";
import {IERC20} from "lib/openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";
import {ILetSwapFactory} from "./interfaces/ILetSwapFactory.sol";
import {ILetSwapFlashSwapHandler} from "./interfaces/ILetSwapFlashSwapHandler.sol";

error LetSwapPair__Lock();
error LetSwapPair__InsufficientLiquidityMinted();
error LetSwapPair__InsufficientLiquidityBurned();
error LetSwapPair__InsufficientLiquidity();
error LetSwapPair__InvalidAddress();
error LetSwapPair__InsufficientOutputAmount();
error LetSwapPair__InsufficientInputAmount();
error LetSwapPair__TransferFailed();
error LetSwapPair__NotFactory();
error LetSwapPair__Overflow();

contract LetSwapPair is ILetSwapPair, LetSwapERC20 {
    uint256 public constant override MINIMUM_LIQUIDITY = 10 ** 3;

    address public immutable override factory;
    address public override token0;
    address public override token1;

    uint256 private reserve0;
    uint256 private reserve1;

    uint256 public override kLast;

    uint256 private unlocked = 1;

    modifier lock() {
        if (unlocked != 1) revert LetSwapPair__Lock();
        unlocked = 0;
        _;
        unlocked = 1;
    }

    /**
     * @dev Transfers tokens safely
     * @param token The address of the token to transfer
     * @param to The address to transfer the tokens to
     * @param value The amount of tokens to transfer
     */
    function _safeTransfer(address token, address to, uint256 value) private {
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(IERC20.transfer.selector, to, value));
        if (!(success && (data.length == 0 || abi.decode(data, (bool))))) {
            revert LetSwapPair__TransferFailed();
        }
    }

    /**
     * @notice Constructor sets the factory address
     */
    constructor() {
        factory = msg.sender;
    }

    /**
     * @notice Initializes the pair with token addresses
     * @param _token0 The address of token0
     * @param _token1 The address of token1
     */
    function initialize(address _token0, address _token1) external override {
        if (msg.sender != factory) {
            revert LetSwapPair__NotFactory();
        }
        token0 = _token0;
        token1 = _token1;
    }

    /**
     * @dev Updates the reserves and emits a Sync event
     * @param balance0 The new balance of token0
     * @param balance1 The new balance of token1
     */
    function _update(uint256 balance0, uint256 balance1) private {
        if (balance0 > type(uint256).max || balance1 > type(uint256).max) {
            revert LetSwapPair__Overflow();
        }
        reserve0 = balance0;
        reserve1 = balance1;
        emit Sync(reserve0, reserve1);
    }

    /**
     * @dev Mints fee if fee is on
     * @param _reserve0 The reserve of token0
     * @param _reserve1 The reserve of token1
     * @return feeOn Boolean indicating if fee is on
     */
    function _mintFee(uint256 _reserve0, uint256 _reserve1) private returns (bool feeOn) {
        address feeTo = ILetSwapFactory(factory).feeTo();
        feeOn = feeTo != address(0);
        uint256 _kLast = kLast;
        if (feeOn) {
            if (_kLast != 0) {
                uint256 rootK = Math.sqrt(uint256(_reserve0) * _reserve1);
                uint256 rootKLast = Math.sqrt(_kLast);
                if (rootK > rootKLast) {
                    unchecked {
                        uint256 numerator = totalSupply * (rootK - rootKLast);
                        uint256 denominator = rootK * 5 + rootKLast;
                        uint256 liquidity = numerator / denominator;
                        if (liquidity > 0) _mint(feeTo, liquidity);
                    }
                }
            }
        } else if (_kLast != 0) {
            kLast = 0;
        }
    }

    /**
     * @notice Mints liquidity tokens
     * @param to The address to mint the liquidity tokens to
     * @return liquidity The amount of liquidity tokens minted
     */
    function mint(address to) external override lock returns (uint256 liquidity) {
        uint256 _reserve0 = reserve0;
        uint256 _reserve1 = reserve1;
        uint256 balance0 = IERC20(token0).balanceOf(address(this));
        uint256 balance1 = IERC20(token1).balanceOf(address(this));
        uint256 amount0 = balance0 - _reserve0;
        uint256 amount1 = balance1 - _reserve1;
        unchecked {
            bool feeOn = _mintFee(_reserve0, _reserve1);
            uint256 _totalSupply = totalSupply;
            if (_totalSupply == 0) {
                liquidity = Math.sqrt(amount0 * amount1) - MINIMUM_LIQUIDITY;
                _mint(address(0), MINIMUM_LIQUIDITY);
            } else {
                liquidity = Math.min((amount0 * _totalSupply) / _reserve0, (amount1 * _totalSupply) / _reserve1);
            }
            if (liquidity <= 0) {
                revert LetSwapPair__InsufficientLiquidityMinted();
            }
            _mint(to, liquidity);

            _update(balance0, balance1);
            if (feeOn) kLast = reserve0 * reserve1;
            emit Mint(msg.sender, amount0, amount1);
        }
    }

    /**
     * @notice Burns liquidity tokens
     * @param to The address to send the underlying tokens to
     * @return amount0 The amount of token0 sent
     * @return amount1 The amount of token1 sent
     */
    function burn(address to) external override lock returns (uint256 amount0, uint256 amount1) {
        uint256 _reserve0 = reserve0;
        uint256 _reserve1 = reserve1;
        address _token0 = token0;
        address _token1 = token1;
        uint256 balance0 = IERC20(_token0).balanceOf(address(this));
        uint256 balance1 = IERC20(_token1).balanceOf(address(this));
        uint256 liquidity = balanceOf[address(this)];

        bool feeOn = _mintFee(_reserve0, _reserve1);
        uint256 _totalSupply = totalSupply;
        unchecked {
            amount0 = (liquidity * balance0) / _totalSupply;
            amount1 = (liquidity * balance1) / _totalSupply;
            if (amount0 <= 0 && amount1 <= 0) {
                revert LetSwapPair__InsufficientLiquidityMinted();
            }
            _burn(address(this), liquidity);
            _safeTransfer(_token0, to, amount0);
            _safeTransfer(_token1, to, amount1);
            balance0 = IERC20(_token0).balanceOf(address(this));
            balance1 = IERC20(_token1).balanceOf(address(this));

            _update(balance0, balance1);
            if (feeOn) kLast = uint256(reserve0) * reserve1;
            emit Burn(msg.sender, amount0, amount1, to);
        }
    }

    /**
     * @notice Swaps tokens
     * @param amount0Out The amount of token0 to send out
     * @param amount1Out The amount of token1 to send out
     * @param to The address to send the tokens to
     * @param data Additional data to pass to the recipient
     */
    function swap(uint256 amount0Out, uint256 amount1Out, address to, bytes calldata data) external override lock {
        if (amount0Out <= 0 && amount1Out <= 0) {
            revert LetSwapPair__InsufficientOutputAmount();
        }
        uint256 _reserve0 = reserve0;
        uint256 _reserve1 = reserve1;
        if (amount0Out >= _reserve0 || amount1Out >= _reserve1) {
            revert LetSwapPair__InsufficientLiquidity();
        }

        uint256 balance0;
        uint256 balance1;
        {
            address _token0 = token0;
            address _token1 = token1;
            if (to == _token0 || to == _token1) {
                revert LetSwapPair__InvalidAddress();
            }
            if (amount0Out > 0) _safeTransfer(_token0, to, amount0Out);
            if (amount1Out > 0) _safeTransfer(_token1, to, amount1Out);
            if (data.length > 0) {
                ILetSwapFlashSwapHandler(to).letSwapFlashSwap(msg.sender, amount0Out, amount1Out, data);
            }
            balance0 = IERC20(_token0).balanceOf(address(this));
            balance1 = IERC20(_token1).balanceOf(address(this));
        }
        uint256 amount0In = balance0 > _reserve0 - amount0Out ? balance0 - (_reserve0 - amount0Out) : 0;
        uint256 amount1In = balance1 > _reserve1 - amount1Out ? balance1 - (_reserve1 - amount1Out) : 0;
        if (amount0In <= 0 && amount1In <= 0) {
            revert LetSwapPair__InsufficientInputAmount();
        }
        {
            uint256 balance0Adjusted = balance0 * 1000 - amount0In * 3;
            uint256 balance1Adjusted = balance1 * 1000 - amount1In * 3;
            if (balance0Adjusted * balance1Adjusted < uint256(_reserve0) * _reserve1 * 1e6) {
                revert LetSwapPair__InsufficientLiquidity();
            }
        }

        _update(balance0, balance1);
        emit Swap(msg.sender, amount0In, amount1In, amount0Out, amount1Out, to);
    }

    /**
     * @notice Skims excess tokens to the specified address
     * @param to The address to send the excess tokens to
     */
    function skim(address to) external override lock {
        address _token0 = token0;
        address _token1 = token1;
        _safeTransfer(_token0, to, IERC20(_token0).balanceOf(address(this)) - reserve0);
        _safeTransfer(_token1, to, IERC20(_token1).balanceOf(address(this)) - reserve1);
    }

    function getReserves() external view returns (uint256 _reserve0, uint256 _reserve1) {
        _reserve0 = reserve0;
        _reserve1 = reserve1;
    }
    /**
     * @notice Syncs the reserves with the current balances
     */

    function sync() external override lock {
        _update(IERC20(token0).balanceOf(address(this)), IERC20(token1).balanceOf(address(this)));
    }
}
