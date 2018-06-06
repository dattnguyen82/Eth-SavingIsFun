pragma solidity ^0.4.21;

import "../installed/SafeMath.sol";
import "../installed/Util.sol";

// ----------------------------------------------------------------------------------
// Split-Eth main contract
// Dat Nguyen - 2017
// ----------------------------------------------------------------------------------


contract SplitEth  {

    using SafeMath for uint;

    using Util for string;

    struct Bill {
        uint total;
        uint balance;
        address[] payers;
        mapping(address => uint) paid;
    }

    mapping(address => Bill[]) internal bills;

    function createBill(uint total) public returns (bool result) {
        uint size = bills[msg.sender].push(Bill(total, total, new address[](0)));
        uint id = size.sub(1);
        emit logCreateBill(msg.sender, id);
        return true;
    }

    function payBill(address _owner, uint _id) public payable returns (bool result) {
        emit logPayBill(_owner, _id, msg.sender, msg.value, bills[_owner][_id].balance);
        return fund(_owner, _id, msg.sender, msg.value);
    }

    function fund(address _owner, uint _id, address _sender, uint _value) internal returns (bool result) {
        require(bills[_owner][_id].balance > 0);

        uint paid = _value;
        uint overage = 0;
        if ( bills[_owner][_id].balance < _value  )
        {
            overage = _value.sub(bills[_owner][_id].balance);
            paid = bills[_owner][_id].balance;
        }

        bills[_owner][_id].payers.push(_sender);
        bills[_owner][_id].paid[_sender] = paid;
        bills[_owner][_id].balance = bills[_owner][_id].balance.sub(paid);

        if (bills[_owner][_id].balance == 0)
        {
            _owner.transfer(bills[_owner][_id].total);
            emit logBillSatisfied(_owner, _id, bills[_owner][_id].total);
        }

        if (overage > 0)
        {
            _sender.transfer(overage);
            emit logOverage(_sender, overage);
        }

        emit logFund(_owner, _id, msg.sender, paid, bills[_owner][_id].balance);

        return true;
    }

    function getBill(address _owner, uint _id) view public returns (uint total, uint balance, uint payers) {
        return (bills[_owner][_id].total, bills[_owner][_id].balance, bills[_owner][_id].payers.length);
    }

    function checkIfBillPaid(address _owner, uint _id, address _payer) view public returns (bool paid) {
        if (bills[_owner][_id].paid[_payer] > 0)
            return true;
       return false;
    }

    function () public payable {
        bytes memory idArr = new bytes(msg.data.length);
        bytes memory ownerArr = new bytes(42);

        //get bytes for owner address
        for(uint i = 0; i < 42; i++) {
            ownerArr[i] = msg.data[i];
        }

        //get bytes for id
        for (uint j=43; j<msg.data.length; j++) {
            idArr[j-43] = msg.data[j];
        }

        uint id = string(idArr).parseInt(0);
        address owner = string(ownerArr).parseAddr();

        emit logPayableFallback(owner, id, msg.value, bills[owner][id].balance);

        fund(owner, id, msg.sender, msg.value);
    }

    event logCreateBill(address owner, uint id);
    event logPayBill(address owner, uint id, address payer, uint amount, uint balance);
    event logFund(address owner, uint id, address payer, uint amount, uint balance);
    event logOverage(address payer, uint amount);
    event logBillSatisfied(address owner, uint id, uint total);
    event logPayableFallback(address owner, uint id, uint amount, uint balance);
}
