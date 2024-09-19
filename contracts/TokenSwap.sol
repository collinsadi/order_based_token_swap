// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract TokenSwap {
    struct Order {
        uint256 id;
        address creator;
        IERC20 offerToken;
        uint256 offerAmount;
        IERC20 wantToken;
        uint256 wantAmount;
        bool isActive;
    }

    mapping(uint256 => Order) public orders;

    uint256 public orderCount;

    event OrderCreated(
        uint256 indexed id,
        address indexed creator,
        address offerToken,
        uint256 offerAmount,
        address wantToken,
        uint256 wantAmount
    );

    event OrderFulfilled(
        uint256 indexed id,
        address indexed fulfiller,
        address offerToken,
        uint256 offerAmount,
        address wantToken,
        uint256 wantAmount
    );

    event OrderCancelled(uint256 indexed id, address indexed creator);

    function createOrder(
        address _offerToken,
        uint256 _offerAmount,
        address _wantToken,
        uint256 _wantAmount
    ) external returns (uint256) {
        require(_offerToken != address(0), "Invalid offer token address");
        require(_wantToken != address(0), "Invalid want token address");
        require(_offerAmount > 0, "Offer amount must be greater than 0");
        require(_wantAmount > 0, "Want amount must be greater than 0");

        // check if the user has the amount that they wants to offer
        require(
            IERC20(_offerToken).balanceOf(msg.sender) >= _offerAmount,
            "Insufficient Token"
        );

        // Transfer offer tokens from the creator to the contract
        IERC20(_offerToken).transferFrom(
            msg.sender,
            address(this),
            _offerAmount
        );

        // Increment order count to get a new order ID
        orderCount += 1;
        uint256 newOrderId = orderCount;

        // Create and store the order
        orders[newOrderId] = Order({
            id: newOrderId,
            creator: msg.sender,
            offerToken: IERC20(_offerToken),
            offerAmount: _offerAmount,
            wantToken: IERC20(_wantToken),
            wantAmount: _wantAmount,
            isActive: true
        });

        emit OrderCreated(
            newOrderId,
            msg.sender,
            _offerToken,
            _offerAmount,
            _wantToken,
            _wantAmount
        );

        return newOrderId;
    }

    // Fulfill an existing order
    function fulfillOrder(uint256 _orderId) external {
        Order storage order = orders[_orderId];

        require(order.isActive, "Order is not active");
        require(
            order.creator != msg.sender,
            "Creator cannot fulfill their own order"
        );

        uint256 offerAmount = order.offerAmount;
        uint256 wantAmount = order.wantAmount;

        // checking if the have enough tokens to complete the order

        require(
            order.wantToken.balanceOf(msg.sender) >= wantAmount,
            "Insufficient Tokens"
        );

        // we are assuming that the frontend have carried out the approve function

        order.wantToken.transferFrom(msg.sender, order.creator, wantAmount);

        order.offerToken.transfer(msg.sender, offerAmount);

        // Mark the order as inactive
        // since transaction have been completed
        order.isActive = false;

        emit OrderFulfilled(
            _orderId,
            msg.sender,
            address(order.offerToken),
            offerAmount,
            address(order.wantToken),
            wantAmount
        );
    }

    function cancelOrder(uint256 _orderId) external {
        Order storage order = orders[_orderId];
        require(order.isActive, "Order is not active");
        require(
            order.creator == msg.sender,
            "Only creator can cancel the order"
        );

        // Mark the order as inactive
        order.isActive = false;

        // Return the offered tokens to the creator
        order.offerToken.transfer(order.creator, order.offerAmount);

        emit OrderCancelled(_orderId, msg.sender);
    }
}
