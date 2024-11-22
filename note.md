```javascript
unchecked {
            uint256 amount0 = balance0 - _reserve0;
            uint256 amount1 = balance1 - _reserve1;

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
```

这里面 kLast = reserve0 _ reserve1;可以换成\_reserve0 _ \_reserve1;
