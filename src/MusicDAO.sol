// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "./DaoToken.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";

contract EventDAO is ERC721 {
    DaoToken public daoToken;

    struct Event {
        bool isActive;
        uint256 depositDeadline;
        uint256 voteDeadline;
        mapping(address => uint256) deposits;
        uint256 totalDeposits;
        mapping(bytes32 => uint256) votes; // Votes per country
        bytes32[] voteOptions; // Dynamic array of countries as options
        bytes32 winningOption; // The winning country
    }

    mapping(uint256 => Event) public events;
    uint256 public nextEventId;

    constructor(address daoTokenAddress) ERC721("EventTicket", "ETK") {
        daoToken = DaoToken(daoTokenAddress);
    }

    function organizeEvent(uint256 depositPeriod, uint256 votePeriod) external {
        uint256 eventId = nextEventId++;
        Event storage newEvent = events[eventId];
        newEvent.isActive = true;
        newEvent.depositDeadline = block.timestamp + depositPeriod;
        newEvent.voteDeadline = newEvent.depositDeadline + votePeriod;
        // Initialize the event further as needed
    }

    function depositTokens(uint256 eventId, uint256 amount) external {
        Event storage event_ = events[eventId];
        require(
            block.timestamp <= event_.depositDeadline,
            "Deposit period has ended"
        );
        require(
            daoToken.transferFrom(msg.sender, address(this), amount),
            "Transfer failed"
        );

        event_.deposits[msg.sender] += amount;
        event_.totalDeposits += amount;
    }

    // Add voting functions and logic here

    // NFT minting function for participants after voting
    function mintNftForParticipants(uint256 eventId) external {
        // Ensure conditions are met, then mint NFT
    }

    function voteForCountry(
        uint256 eventId,
        bytes32 country,
        uint256 amount
    ) external {
        Event storage event_ = events[eventId];
        require(
            block.timestamp <= event_.voteDeadline,
            "Voting period has ended"
        );
        require(
            block.timestamp > event_.depositDeadline,
            "Deposit period not ended"
        );
        require(
            event_.deposits[msg.sender] >= amount,
            "Not enough deposited tokens"
        );

        // Optionally, you might want to lock the tokens used to vote until the voting ends
        event_.votes[country] += amount;

        // Check if the option exists, if not add it
        bool exists = false;
        for (uint i = 0; i < event_.voteOptions.length; i++) {
            if (event_.voteOptions[i] == country) {
                exists = true;
                break;
            }
        }
        if (!exists) {
            event_.voteOptions.push(country);
        }
    }

    function determineWinner(uint256 eventId) external {
        Event storage event_ = events[eventId];
        require(
            block.timestamp > event_.voteDeadline,
            "Voting period not ended"
        );
        require(event_.winningOption == bytes32(0), "Winner already decided");

        uint256 winningVoteCount = 0;
        for (uint i = 0; i < event_.voteOptions.length; i++) {
            bytes32 option = event_.voteOptions[i];
            uint256 optionVote = event_.votes[option];
            if (optionVote > winningVoteCount) {
                winningVoteCount = optionVote;
                event_.winningOption = option;
            }
        }

        require(
            (winningVoteCount * 100) / event_.totalDeposits >= 51,
            "No option has reached the majority"
        );
        // winningOption now holds the country that won the vote
    }
}
