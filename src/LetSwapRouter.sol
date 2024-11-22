// SPDX-License-Identifier: MIT

pragma solidity 0.8.20;

import {ILetSwapFactory} from "./interfaces/ILetSwapFactory.sol";
import {ILetSwapRouter} from "./interfaces/ILetSwapRouter.sol";
import {ILetSwapPair} from "./interfaces/ILetSwapPair.sol";
import {IERC20} from "lib/openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";
import {IWETH} from "./interfaces/IWETH.sol";
import {TransferHelper} from "./libraries/TransferHelper.sol";
import {LetSwapLibrary} from "./libraries/LetSwapLibrary.sol";

error LetSwapRouter__Expired();
error LetSwapRouter__InsufficientBAmount();
error LetSwapRouter__InsufficientAAmount();
error LetSwapRouter__InsufficientOutputAmount();
error LetSwapRouter__ExcessiveInputAmount();
error LetSwapRouter__InvalidPath();

/**
 * @title LetSwapRouter
 * @dev Router contract for LetSwap decentralized exchange
 */
contract LetSwapRouter is ILetSwapRouter {
    address public immutable override factory;
    address public immutable override WETH;

    /**
     * @dev Modifier to check if the deadline has passed
     * @param deadline The deadline timestamp
     */
    modifier deadlineCheck(uint256 deadline) {
        if (deadline < block.timestamp) {
            revert LetSwapRouter__Expired();
        }
        _;
    }

    /**
     * @dev Constructor to set factory and WETH addresses
     * @param _factory The address of the LetSwap factory
     * @param _WETH The address of the WETH token
     */
    constructor(address _factory, address _WETH) {
        factory = _factory;
        WETH = _WETH;
    }

    receive() external payable {
        assert(msg.sender == WETH);
    }

    /**
     * @dev Internal function to add liquidity
     * @param tokenA The address of token A
     * @param tokenB The address of token B
     * @param amountADesired The desired amount of token A
     * @param amountBDesired The desired amount of token B
     * @param amountAMin The minimum amount of token A
     * @param amountBMin The minimum amount of token B
     * @return amountA The amount of token A added
     * @return amountB The amount of token B added
     */
    function _addLiquidity(
        address tokenA,
        address tokenB,
        uint256 amountADesired,
        uint256 amountBDesired,
        uint256 amountAMin,
        uint256 amountBMin
    ) internal virtual returns (uint256 amountA, uint256 amountB) {
        if (ILetSwapFactory(factory).getPair(tokenA, tokenB) == address(0)) {
            ILetSwapFactory(factory).createPair(tokenA, tokenB);
        }

        (uint256 reserveA, uint256 reserveB) = LetSwapLibrary.getReserves(factory, tokenA, tokenB);

        if (reserveA == 0 && reserveB == 0) {
            (amountA, amountB) = (amountADesired, amountBDesired);
        } else {
            uint256 amountBOptimal = LetSwapLibrary.quote(amountADesired, reserveA, reserveB);
            if (amountBOptimal <= amountBDesired) {
                if (amountBOptimal < amountBMin) {
                    revert LetSwapRouter__InsufficientBAmount();
                }
                (amountA, amountB) = (amountADesired, amountBOptimal);
            } else {
                uint256 amountAOptimal = LetSwapLibrary.quote(amountBDesired, reserveB, reserveA);
                assert(amountAOptimal <= amountADesired);
                if (amountAOptimal < amountAMin) {
                    revert LetSwapRouter__InsufficientAAmount();
                }
                (amountA, amountB) = (amountAOptimal, amountBDesired);
            }
        }
    }

    /**
     * @dev External function to add liquidity
     * @param tokenA The address of token A
     * @param tokenB The address of token B
     * @param amountADesired The desired amount of token A
     * @param amountBDesired The desired amount of token B
     * @param amountAMin The minimum amount of token A
     * @param amountBMin The minimum amount of token B
     * @param to The address to receive the liquidity tokens
     * @param deadline The deadline timestamp
     * @return amountA The amount of token A added
     * @return amountB The amount of token B added
     * @return liquidity The amount of liquidity tokens minted
     */
    function addLiquidity(
        address tokenA,
        address tokenB,
        uint256 amountADesired,
        uint256 amountBDesired,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    ) external virtual override deadlineCheck(deadline) returns (uint256 amountA, uint256 amountB, uint256 liquidity) {
        (amountA, amountB) = _addLiquidity(tokenA, tokenB, amountADesired, amountBDesired, amountAMin, amountBMin);
        address pair = LetSwapLibrary.pairFor(factory, tokenA, tokenB);
        TransferHelper.safeTransferFrom(tokenA, msg.sender, pair, amountA);
        TransferHelper.safeTransferFrom(tokenB, msg.sender, pair, amountB);
        liquidity = ILetSwapPair(pair).mint(to);
    }

    /**
     * @dev External function to add liquidity with ETH
     * @param token The address of the token
     * @param amountTokenDesired The desired amount of the token
     * @param amountTokenMin The minimum amount of the token
     * @param amountETHMin The minimum amount of ETH
     * @param to The address to receive the liquidity tokens
     * @param deadline The deadline timestamp
     * @return amountToken The amount of the token added
     * @return amountETH The amount of ETH added
     * @return liquidity The amount of liquidity tokens minted
     */
    function addLiquidityETH(
        address token,
        uint256 amountTokenDesired,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    )
        external
        payable
        virtual
        override
        deadlineCheck(deadline)
        returns (uint256 amountToken, uint256 amountETH, uint256 liquidity)
    {
        (amountToken, amountETH) =
            _addLiquidity(token, WETH, amountTokenDesired, msg.value, amountTokenMin, amountETHMin);
        address pair = LetSwapLibrary.pairFor(factory, token, WETH);

        TransferHelper.safeTransferFrom(token, msg.sender, pair, amountToken);
        IWETH(WETH).deposit{value: amountETH}();
        assert(IWETH(WETH).transfer(pair, amountETH));
        liquidity = ILetSwapPair(pair).mint(to);
        // refund dust eth, if any
        if (msg.value > amountETH) {
            TransferHelper.safeTransferETH(msg.sender, msg.value - amountETH);
        }
    }

    /**
     * @dev External function to remove liquidity
     * @param tokenA The address of token A
     * @param tokenB The address of token B
     * @param liquidity The amount of liquidity tokens to remove
     * @param amountAMin The minimum amount of token A
     * @param amountBMin The minimum amount of token B
     * @param to The address to receive the tokens
     * @param deadline The deadline timestamp
     * @return amountA The amount of token A removed
     * @return amountB The amount of token B removed
     */
    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint256 liquidity,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    ) public virtual override deadlineCheck(deadline) returns (uint256 amountA, uint256 amountB) {
        address pair = LetSwapLibrary.pairFor(factory, tokenA, tokenB);
        ILetSwapPair(pair).transferFrom(msg.sender, pair, liquidity); // send liquidity to pair
        (uint256 amount0, uint256 amount1) = ILetSwapPair(pair).burn(to);
        (address token0,) = LetSwapLibrary.sortTokens(tokenA, tokenB);
        (amountA, amountB) = tokenA == token0 ? (amount0, amount1) : (amount1, amount0);
        if (amountA < amountAMin) {
            revert LetSwapRouter__InsufficientAAmount();
        }
        if (amountB < amountBMin) {
            revert LetSwapRouter__InsufficientBAmount();
        }
    }

    /**
     * @dev External function to remove liquidity with ETH
     * @param token The address of the token
     * @param liquidity The amount of liquidity tokens to remove
     * @param amountTokenMin The minimum amount of the token
     * @param amountETHMin The minimum amount of ETH
     * @param to The address to receive the tokens
     * @param deadline The deadline timestamp
     * @return amountToken The amount of the token removed
     * @return amountETH The amount of ETH removed
     */
    function removeLiquidityETH(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    ) public virtual override deadlineCheck(deadline) returns (uint256 amountToken, uint256 amountETH) {
        (amountToken, amountETH) =
            removeLiquidity(token, WETH, liquidity, amountTokenMin, amountETHMin, address(this), deadline);
        TransferHelper.safeTransfer(token, to, amountToken);
        IWETH(WETH).withdraw(amountETH);
        TransferHelper.safeTransferETH(to, amountETH);
    }

    /**
     * @dev External function to remove liquidity with permit
     * @param tokenA The address of token A
     * @param tokenB The address of token B
     * @param liquidity The amount of liquidity tokens to remove
     * @param amountAMin The minimum amount of token A
     * @param amountBMin The minimum amount of token B
     * @param to The address to receive the tokens
     * @param deadline The deadline timestamp
     * @param approveMax Whether to approve the maximum amount
     * @param v The ECDSA signature parameter
     * @param r The ECDSA signature parameter
     * @param s The ECDSA signature parameter
     * @return amountA The amount of token A removed
     * @return amountB The amount of token B removed
     */
    function removeLiquidityWithPermit(
        address tokenA,
        address tokenB,
        uint256 liquidity,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external virtual override returns (uint256 amountA, uint256 amountB) {
        address pair = LetSwapLibrary.pairFor(factory, tokenA, tokenB);
        uint256 value = approveMax ? type(uint256).max : liquidity;
        ILetSwapPair(pair).permit(msg.sender, address(this), value, deadline, v, r, s);
        (amountA, amountB) = removeLiquidity(tokenA, tokenB, liquidity, amountAMin, amountBMin, to, deadline);
    }

    /**
     * @dev External function to remove liquidity with ETH and permit
     * @param token The address of the token
     * @param liquidity The amount of liquidity tokens to remove
     * @param amountTokenMin The minimum amount of the token
     * @param amountETHMin The minimum amount of ETH
     * @param to The address to receive the tokens
     * @param deadline The deadline timestamp
     * @param approveMax Whether to approve the maximum amount
     * @param v The ECDSA signature parameter
     * @param r The ECDSA signature parameter
     * @param s The ECDSA signature parameter
     * @return amountToken The amount of the token removed
     * @return amountETH The amount of ETH removed
     */
    function removeLiquidityETHWithPermit(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external virtual override returns (uint256 amountToken, uint256 amountETH) {
        address pair = LetSwapLibrary.pairFor(factory, token, WETH);
        uint256 value = approveMax ? type(uint256).max : liquidity;
        ILetSwapPair(pair).permit(msg.sender, address(this), value, deadline, v, r, s);
        (amountToken, amountETH) = removeLiquidityETH(token, liquidity, amountTokenMin, amountETHMin, to, deadline);
    }

    /**
     * @dev External function to remove liquidity with ETH supporting fee-on-transfer tokens
     * @param token The address of the token
     * @param liquidity The amount of liquidity tokens to remove
     * @param amountTokenMin The minimum amount of the token
     * @param amountETHMin The minimum amount of ETH
     * @param to The address to receive the tokens
     * @param deadline The deadline timestamp
     * @return amountETH The amount of ETH removed
     */
    function removeLiquidityETHSupportingFeeOnTransferTokens(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    ) public virtual override deadlineCheck(deadline) returns (uint256 amountETH) {
        (, amountETH) = removeLiquidity(token, WETH, liquidity, amountTokenMin, amountETHMin, address(this), deadline);
        TransferHelper.safeTransfer(token, to, IERC20(token).balanceOf(address(this)));
        IWETH(WETH).withdraw(amountETH);
        TransferHelper.safeTransferETH(to, amountETH);
    }

    /**
     * @dev External function to remove liquidity with ETH and permit supporting fee-on-transfer tokens
     * @param token The address of the token
     * @param liquidity The amount of liquidity tokens to remove
     * @param amountTokenMin The minimum amount of the token
     * @param amountETHMin The minimum amount of ETH
     * @param to The address to receive the tokens
     * @param deadline The deadline timestamp
     * @param approveMax Whether to approve the maximum amount
     * @param v The ECDSA signature parameter
     * @param r The ECDSA signature parameter
     * @param s The ECDSA signature parameter
     * @return amountETH The amount of ETH removed
     */
    function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external virtual override returns (uint256 amountETH) {
        address pair = LetSwapLibrary.pairFor(factory, token, WETH);
        uint256 value = approveMax ? type(uint256).max : liquidity;
        ILetSwapPair(pair).permit(msg.sender, address(this), value, deadline, v, r, s);
        amountETH = removeLiquidityETHSupportingFeeOnTransferTokens(
            token, liquidity, amountTokenMin, amountETHMin, to, deadline
        );
    }

    /**
     * @dev Internal function to swap tokens
     * @param amounts The amounts of tokens to swap
     * @param path The path of tokens to swap
     * @param _to The address to receive the final token
     */
    function _swap(uint256[] memory amounts, address[] memory path, address _to) internal virtual {
        uint256 pathLength = path.length;
        for (uint256 i; i < pathLength - 1;) {
            (address input, address output) = (path[i], path[i + 1]);
            (address token0,) = LetSwapLibrary.sortTokens(input, output);
            uint256 amountOut = amounts[i + 1];
            (uint256 amount0Out, uint256 amount1Out) =
                input == token0 ? (uint256(0), amountOut) : (amountOut, uint256(0));
            address to = i < path.length - 2 ? LetSwapLibrary.pairFor(factory, output, path[i + 2]) : _to;
            ILetSwapPair(LetSwapLibrary.pairFor(factory, input, output)).swap(amount0Out, amount1Out, to, new bytes(0));
            unchecked {
                ++i;
            }
        }
    }

    /**
     * @dev External function to swap exact tokens for tokens
     * @param amountIn The amount of the first token to swap
     * @param amountOutMin The minimum amount of the last token to receive
     * @param path The path of tokens to swap
     * @param to The address to receive the final token
     * @param deadline The deadline timestamp
     * @return amounts The amounts of tokens swapped
     */
    function swapExactTokensForTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external virtual override deadlineCheck(deadline) returns (uint256[] memory amounts) {
        amounts = LetSwapLibrary.getAmountsOut(factory, amountIn, path);
        if (amounts[amounts.length - 1] < amountOutMin) {
            revert LetSwapRouter__InsufficientOutputAmount();
        }
        TransferHelper.safeTransferFrom(
            path[0], msg.sender, LetSwapLibrary.pairFor(factory, path[0], path[1]), amounts[0]
        );
        _swap(amounts, path, to);
    }

    /**
     * @dev External function to swap tokens for exact tokens
     * @param amountOut The amount of the last token to receive
     * @param amountInMax The maximum amount of the first token to swap
     * @param path The path of tokens to swap
     * @param to The address to receive the final token
     * @param deadline The deadline timestamp
     * @return amounts The amounts of tokens swapped
     */
    function swapTokensForExactTokens(
        uint256 amountOut,
        uint256 amountInMax,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external virtual override deadlineCheck(deadline) returns (uint256[] memory amounts) {
        amounts = LetSwapLibrary.getAmountsIn(factory, amountOut, path);
        if (amounts[0] > amountInMax) {
            revert LetSwapRouter__ExcessiveInputAmount();
        }
        TransferHelper.safeTransferFrom(
            path[0], msg.sender, LetSwapLibrary.pairFor(factory, path[0], path[1]), amounts[0]
        );
        _swap(amounts, path, to);
    }

    /**
     * @dev External function to swap exact ETH for tokens
     * @param amountOutMin The minimum amount of the last token to receive
     * @param path The path of tokens to swap
     * @param to The address to receive the final token
     * @param deadline The deadline timestamp
     * @return amounts The amounts of tokens swapped
     */
    function swapExactETHForTokens(uint256 amountOutMin, address[] calldata path, address to, uint256 deadline)
        external
        payable
        virtual
        override
        deadlineCheck(deadline)
        returns (uint256[] memory amounts)
    {
        if (path[0] != WETH) {
            revert LetSwapRouter__InvalidPath();
        }
        amounts = LetSwapLibrary.getAmountsOut(factory, msg.value, path);
        if (amounts[amounts.length - 1] < amountOutMin) {
            revert LetSwapRouter__InsufficientOutputAmount();
        }
        IWETH(WETH).deposit{value: amounts[0]}();
        assert(IWETH(WETH).transfer(LetSwapLibrary.pairFor(factory, path[0], path[1]), amounts[0]));
        _swap(amounts, path, to);
    }

    /**
     * @dev External function to swap tokens for exact ETH
     * @param amountOut The amount of ETH to receive
     * @param amountInMax The maximum amount of the first token to swap
     * @param path The path of tokens to swap
     * @param to The address to receive the final token
     * @param deadline The deadline timestamp
     * @return amounts The amounts of tokens swapped
     */
    function swapTokensForExactETH(
        uint256 amountOut,
        uint256 amountInMax,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external virtual override deadlineCheck(deadline) returns (uint256[] memory amounts) {
        if (path[path.length - 1] != WETH) {
            revert LetSwapRouter__InvalidPath();
        }
        amounts = LetSwapLibrary.getAmountsIn(factory, amountOut, path);
        if (amounts[0] > amountInMax) {
            revert LetSwapRouter__ExcessiveInputAmount();
        }
        TransferHelper.safeTransferFrom(
            path[0], msg.sender, LetSwapLibrary.pairFor(factory, path[0], path[1]), amounts[0]
        );
        _swap(amounts, path, address(this));
        IWETH(WETH).withdraw(amounts[amounts.length - 1]);
        TransferHelper.safeTransferETH(to, amounts[amounts.length - 1]);
    }

    /**
     * @dev External function to swap exact tokens for ETH
     * @param amountIn The amount of the first token to swap
     * @param amountOutMin The minimum amount of ETH to receive
     * @param path The path of tokens to swap
     * @param to The address to receive the final token
     * @param deadline The deadline timestamp
     * @return amounts The amounts of tokens swapped
     */
    function swapExactTokensForETH(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external virtual override deadlineCheck(deadline) returns (uint256[] memory amounts) {
        if (path[path.length - 1] != WETH) {
            revert LetSwapRouter__InvalidPath();
        }
        amounts = LetSwapLibrary.getAmountsOut(factory, amountIn, path);
        if (amounts[amounts.length - 1] < amountOutMin) {
            revert LetSwapRouter__InsufficientOutputAmount();
        }
        TransferHelper.safeTransferFrom(
            path[0], msg.sender, LetSwapLibrary.pairFor(factory, path[0], path[1]), amounts[0]
        );
        _swap(amounts, path, address(this));
        IWETH(WETH).withdraw(amounts[amounts.length - 1]);
        TransferHelper.safeTransferETH(to, amounts[amounts.length - 1]);
    }

    /**
     * @dev External function to swap ETH for exact tokens
     * @param amountOut The amount of the last token to receive
     * @param path The path of tokens to swap
     * @param to The address to receive the final token
     * @param deadline The deadline timestamp
     * @return amounts The amounts of tokens swapped
     */
    function swapETHForExactTokens(uint256 amountOut, address[] calldata path, address to, uint256 deadline)
        external
        payable
        virtual
        override
        deadlineCheck(deadline)
        returns (uint256[] memory amounts)
    {
        if (path[0] != WETH) {
            revert LetSwapRouter__InvalidPath();
        }
        amounts = LetSwapLibrary.getAmountsIn(factory, amountOut, path);
        if (amounts[0] > msg.value) {
            revert LetSwapRouter__ExcessiveInputAmount();
        }
        IWETH(WETH).deposit{value: amounts[0]}();
        assert(IWETH(WETH).transfer(LetSwapLibrary.pairFor(factory, path[0], path[1]), amounts[0]));
        _swap(amounts, path, to);
        // refund dust eth, if any
        if (msg.value > amounts[0]) {
            TransferHelper.safeTransferETH(msg.sender, msg.value - amounts[0]);
        }
    }

    /**
     * @dev Internal function to swap tokens supporting fee-on-transfer tokens
     * @param path The path of tokens to swap
     * @param _to The address to receive the final token
     */
    function _swapSupportingFeeOnTransferTokens(address[] memory path, address _to) internal virtual {
        uint256 pathLength = path.length;
        for (uint256 i; i < pathLength - 1;) {
            (address input, address output) = (path[i], path[i + 1]);
            (address token0,) = LetSwapLibrary.sortTokens(input, output);
            ILetSwapPair pair = ILetSwapPair(LetSwapLibrary.pairFor(factory, input, output));
            uint256 amountInput;
            uint256 amountOutput;
            {
                // scope to avoid stack too deep errors
                (uint256 reserve0, uint256 reserve1) = pair.getReserves();
                (uint256 reserveInput, uint256 reserveOutput) =
                    input == token0 ? (reserve0, reserve1) : (reserve1, reserve0);
                amountInput = IERC20(input).balanceOf(address(pair)) - reserveInput;
                amountOutput = LetSwapLibrary.getAmountOut(amountInput, reserveInput, reserveOutput);
            }
            (uint256 amount0Out, uint256 amount1Out) =
                input == token0 ? (uint256(0), amountOutput) : (amountOutput, uint256(0));
            address to = i < path.length - 2 ? LetSwapLibrary.pairFor(factory, output, path[i + 2]) : _to;
            pair.swap(amount0Out, amount1Out, to, new bytes(0));
            unchecked {
                ++i;
            }
        }
    }

    /**
     * @dev External function to swap exact tokens for tokens supporting fee-on-transfer tokens
     * @param amountIn The amount of the first token to swap
     * @param amountOutMin The minimum amount of the last token to receive
     * @param path The path of tokens to swap
     * @param to The address to receive the final token
     * @param deadline The deadline timestamp
     */
    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external virtual override deadlineCheck(deadline) {
        TransferHelper.safeTransferFrom(
            path[0], msg.sender, LetSwapLibrary.pairFor(factory, path[0], path[1]), amountIn
        );
        uint256 balanceBefore = IERC20(path[path.length - 1]).balanceOf(to);
        _swapSupportingFeeOnTransferTokens(path, to);
        if (IERC20(path[path.length - 1]).balanceOf(to) - balanceBefore < amountOutMin) {
            revert LetSwapRouter__InsufficientOutputAmount();
        }
    }

    /**
     * @dev External function to swap exact ETH for tokens supporting fee-on-transfer tokens
     * @param amountOutMin The minimum amount of the last token to receive
     * @param path The path of tokens to swap
     * @param to The address to receive the final token
     * @param deadline The deadline timestamp
     */
    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable virtual override deadlineCheck(deadline) {
        if (path[0] != WETH) {
            revert LetSwapRouter__InvalidPath();
        }
        uint256 amountIn = msg.value;
        IWETH(WETH).deposit{value: amountIn}();
        assert(IWETH(WETH).transfer(LetSwapLibrary.pairFor(factory, path[0], path[1]), amountIn));
        uint256 balanceBefore = IERC20(path[path.length - 1]).balanceOf(to);
        _swapSupportingFeeOnTransferTokens(path, to);
        if (IERC20(path[path.length - 1]).balanceOf(to) - balanceBefore < amountOutMin) {
            revert LetSwapRouter__InsufficientOutputAmount();
        }
    }

    /**
     * @dev External function to swap exact tokens for ETH supporting fee-on-transfer tokens
     * @param amountIn The amount of the first token to swap
     * @param amountOutMin The minimum amount of ETH to receive
     * @param path The path of tokens to swap
     * @param to The address to receive the final token
     * @param deadline The deadline timestamp
     */
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external virtual override deadlineCheck(deadline) {
        if (path[path.length - 1] != WETH) {
            revert LetSwapRouter__InvalidPath();
        }
        TransferHelper.safeTransferFrom(
            path[0], msg.sender, LetSwapLibrary.pairFor(factory, path[0], path[1]), amountIn
        );
        _swapSupportingFeeOnTransferTokens(path, address(this));
        uint256 amountOut = IERC20(WETH).balanceOf(address(this));
        if (amountOut < amountOutMin) {
            revert LetSwapRouter__InsufficientOutputAmount();
        }
        IWETH(WETH).withdraw(amountOut);
        TransferHelper.safeTransferETH(to, amountOut);
    }

    /**
     * @dev External function to get the amount of output token for a given input token
     * @param amountA The amount of the input token
     * @param reserveA The reserve of the input token
     * @param reserveB The reserve of the output token
     * @return amountB The amount of the output token
     */
    function quote(uint256 amountA, uint256 reserveA, uint256 reserveB)
        public
        pure
        virtual
        override
        returns (uint256 amountB)
    {
        return LetSwapLibrary.quote(amountA, reserveA, reserveB);
    }

    /**
     * @dev External function to get the amount of output token for a given input token
     * @param amountIn The amount of the input token
     * @param reserveIn The reserve of the input token
     * @param reserveOut The reserve of the output token
     * @return amountOut The amount of the output token
     */
    function getAmountOut(uint256 amountIn, uint256 reserveIn, uint256 reserveOut)
        public
        pure
        virtual
        override
        returns (uint256 amountOut)
    {
        return LetSwapLibrary.getAmountOut(amountIn, reserveIn, reserveOut);
    }

    /**
     * @dev External function to get the amount of input token for a given output token
     * @param amountOut The amount of the output token
     * @param reserveIn The reserve of the input token
     * @param reserveOut The reserve of the output token
     * @return amountIn The amount of the input token
     */
    function getAmountIn(uint256 amountOut, uint256 reserveIn, uint256 reserveOut)
        public
        pure
        virtual
        override
        returns (uint256 amountIn)
    {
        return LetSwapLibrary.getAmountIn(amountOut, reserveIn, reserveOut);
    }

    /**
     * @dev External function to get the amounts of output tokens for a given input token
     * @param amountIn The amount of the input token
     * @param path The path of tokens
     * @return amounts The amounts of output tokens
     */
    function getAmountsOut(uint256 amountIn, address[] memory path)
        public
        view
        virtual
        override
        returns (uint256[] memory amounts)
    {
        return LetSwapLibrary.getAmountsOut(factory, amountIn, path);
    }

    /**
     * @dev External function to get the amounts of input tokens for a given output token
     * @param amountOut The amount of the output token
     * @param path The path of tokens
     * @return amounts The amounts of input tokens
     */
    function getAmountsIn(uint256 amountOut, address[] memory path)
        public
        view
        virtual
        override
        returns (uint256[] memory amounts)
    {
        return LetSwapLibrary.getAmountsIn(factory, amountOut, path);
    }
}
