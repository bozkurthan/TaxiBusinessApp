//CMP 619 Project-Spring 2021
// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;
import "CMP619Project.sol"; 


//CMP 619 Project-Spring 2021


contract TaxiBusinessApp {
    struct Participant {
        address payable participantAdress;
        uint partipicant_account;
    }
    
    struct TaxiDriver {
        address payable driverAdress;
        uint salary;
        uint account;
    }
    
    struct ProposedDriver {
        TaxiDriver taxiDriver;
        uint8 approvalState;
    }
    mapping (address => bool) driverApprovedParticipants;

    
    struct ProposedCar {
        uint256 carID;
        uint price;
        uint offerValidTime;  
        uint8 approvalState;
    }
    mapping (address => bool) carApprovedParticipants;

    
    address payable public manager;
    address payable public carDealer;
    
    address payable[] public participantArray;
    mapping(address => Participant) public participants;
    
    uint256 public contractBalance;
    uint fixedExpenses = 10 ether;
    uint participationFee = 100 ether;
    
    TaxiDriver public taxiDriver;
    ProposedDriver proposedDriver;
    
    uint256 public ownedCar;
    ProposedCar proposedCar;
    ProposedCar proposedRepurchaseCar;
    
    
    // Timing
    uint256 startTime;
    uint256 lastSalaryTime;
    uint256 lastDividendTime;
    uint256 lastCarExpensesTime;
    
    // Events
    event MaintenanceExpenseEvent (
        string eventType,
        address to,
        uint timestamp,
        uint amount
    );
    
    modifier onlyManager {
        require(msg.sender == manager, "Only managers.");
        _;
    }
    
    modifier onlyCarDealer {
        require(msg.sender == carDealer, "Only car dealers.");
        _;
    }
    
    modifier onlyDriver {
        require(msg.sender == taxiDriver.driverAdress, "Only driver.");
        _;
    }
    
    modifier onlyParticipants {
        require(participants[msg.sender].participantAdress == msg.sender, "Only participants.");
        _;
    }
    
    constructor() public {
        manager = payable(msg.sender);
        contractBalance = 0;
        
        startTime = block.timestamp;
        lastDividendTime = block.timestamp;
        lastCarExpensesTime = block.timestamp;
    }
    
    function getParticipantCount() public view returns(uint) {
        return participantArray.length;
    }
    
    function getParticipantDetails(uint participantIndex) public view returns(uint, address payable, uint, uint) {
        return (
            participantIndex,
            participantArray[participantIndex],
            address(participantArray[participantIndex]).balance,
            participants[participantArray[participantIndex]].partipicant_account
        );
    }
    
    //
    function join() external payable {
        require(participantArray.length < 9, 'Maximum participant count (9) has been reached!');
        require(msg.value == participationFee, 'Sent value must be 100 ether!');
        require(participants[msg.sender].participantAdress != msg.sender, 'This account already participated into the contract');
        
        // Increase the contractBalance
        contractBalance += participationFee;
    
        // Insert the address into participants
        participants[payable(msg.sender)] = Participant({participantAdress: payable(msg.sender), partipicant_account: 1 ether});
        participantArray.push(payable(msg.sender));
    }
    
    //
    function setCarDealer(address payable _carDealer) public onlyManager {
        carDealer = _carDealer;
    }
    
    //
    function carProposeToBusiness(uint256 _carID, uint _price, uint _offerValidTime) public onlyCarDealer {
        // ProposedCar storage proposedCar = new ProposedCar;
        // proposedCar.carID = _carID;
        // proposedCar.price = _price;
        // proposedCar.offerValidTime = _offerValidTime;
        // proposedCar.approvalState = 0;
        proposedCar = ProposedCar({
            carID: _carID,
            price: _price,
            offerValidTime: _offerValidTime,
            approvalState: 0
        });
        
        // Clear participant votings
        for (uint i = 0; i < participantArray.length; i++) {
            carApprovedParticipants[participantArray[i]] = false;
        }
    }
    
    //
    function approvePurchaseCar() public onlyParticipants {
        require(carApprovedParticipants[msg.sender] == false, 'This participant already approved for this car.');

        carApprovedParticipants[msg.sender] = true;
        proposedCar.approvalState++;
    }
    
    //
    function purchaseCar() public onlyManager {
        require(block.timestamp < proposedCar.offerValidTime, 'Offer valid time has been exeeded.');
        require(proposedCar.approvalState > (participantArray.length / 2), 'More than half of the participants must approve to be able to purchase the car.');
        
        ownedCar = proposedCar.carID;
        
        emit MaintenanceExpenseEvent('Car Purchase', carDealer, block.timestamp, proposedCar.price);
        carDealer.transfer(proposedCar.price);  // Transfer the price
    }
    
    // 
    function repurchaseCarPropose(uint256 _carID, uint _price, uint _offerValidTime) public onlyCarDealer {
        proposedRepurchaseCar = ProposedCar({
            carID: _carID,
            price: _price,
            offerValidTime: _offerValidTime,
            approvalState: 0
        });
        
        // Clear participant votings
        for (uint i = 0; i < participantArray.length; i++) {
            carApprovedParticipants[participantArray[i]] = false;
        }
    }
    
    //
    function approveSellProposal() public onlyParticipants {
        require(carApprovedParticipants[msg.sender] == false, 'This participant already approved for this car.');
        
        carApprovedParticipants[msg.sender] = true;
        proposedRepurchaseCar.approvalState++;
    }
    
    //
    function repurchaseCar() public payable onlyCarDealer {
        require(block.timestamp < proposedRepurchaseCar.offerValidTime && proposedRepurchaseCar.approvalState > (participantArray.length / 2));
    }
    
    // 
    function proposeDriver(address payable _driverAdress, uint _salary) public onlyManager {
        proposedDriver = ProposedDriver({
            taxiDriver: TaxiDriver({
                driverAdress: _driverAdress,
                salary: _salary,
                account: 0
            }),
            approvalState: 0
        });
        
        // Clear participant votings
        for (uint i = 0; i < participantArray.length; i++) {
            driverApprovedParticipants[participantArray[i]] = false;
        }
    }
    
    //
    function approveDriver() public onlyParticipants {
        require(driverApprovedParticipants[msg.sender] == false, 'This participant already approved for this car.');

        driverApprovedParticipants[msg.sender] = true;
        proposedDriver.approvalState++;
    }
    
    //
    function setDriver() public onlyManager {
        require(proposedDriver.approvalState > (participantArray.length / 2), 'More than half of the participants must approve to be able to purchase the car.');

        taxiDriver = proposedDriver.taxiDriver;
        lastSalaryTime = block.timestamp;
    }
    
    //
    function fireDriver() public onlyManager {
        taxiDriver.account += taxiDriver.salary;
        contractBalance -= taxiDriver.salary;
    }
    
    //
    function getCharge() public payable {
        contractBalance += msg.value;
    }
    
    //
    function releaseSalary() public onlyManager {
        require(block.timestamp >= lastSalaryTime + 30 days);
        lastSalaryTime = block.timestamp;
        
        taxiDriver.account += taxiDriver.salary;
        contractBalance -= taxiDriver.salary;
    }
    
    // 
    function getSalary() public onlyDriver {
        require (taxiDriver.account > 0);
        
        // Copy account balance
        uint tmp_account = taxiDriver.account;
        taxiDriver.account = 0;
        
        // Log the event
        emit MaintenanceExpenseEvent('Driver Salary', taxiDriver.driverAdress, block.timestamp, tmp_account);
        
        // Withdraw the money
        taxiDriver.driverAdress.transfer(tmp_account);
    }
    
    // 
    function carExpenses() public onlyManager {
        require(block.timestamp >= lastCarExpensesTime + 180 days);
        lastCarExpensesTime = block.timestamp;
        
        // Decrement the contract balance
        contractBalance -= fixedExpenses;
        
        // Log the event
        emit MaintenanceExpenseEvent('Car Expenses', carDealer, block.timestamp, fixedExpenses);
        
        // Transfer the expenses
        carDealer.transfer(fixedExpenses);
    }
    
    // 
    function payDividend() public onlyManager {
        require(block.timestamp >= lastDividendTime + 180 days);
        
        // Expenses
        carExpenses();
        releaseSalary();
        
        // Share the profit among the participants
        uint dividend = contractBalance / participantArray.length;
        for (uint i = 0; i < participantArray.length; i++) {
            participants[participantArray[i]].partipicant_account += dividend;
            contractBalance -= dividend;
        }
        
        lastDividendTime = block.timestamp;
    }
    
    //GetDividend:
    /*Only Participants can call this function, if there is any money in participants’ account, it will be send to his/her address*/
    
    function getDividend() public onlyParticipants {
        uint temp_part_blnc = participants[msg.sender].partipicant_account;
        participants[msg.sender].partipicant_account = 0;
        
        // Log the event
        emit MaintenanceExpenseEvent('Participant Dividend', msg.sender, block.timestamp, temp_part_blnc);
        
        // Get back
        payable(msg.sender).transfer(temp_part_blnc);
    }
    
    // Fallback Function:
    // To fallback external declarition is needed
    fallback() external {
        revert ();
    }
    
    receive() external payable {
        revert ();
    }
}
