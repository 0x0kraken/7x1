// SPDX-License-Identifier: MIT
pragma solidity ^0.8.22;

import {ERC20} from "@openzeppelin/contracts@5.1.0/token/ERC20/ERC20.sol";
import {ERC20Burnable} from "@openzeppelin/contracts@5.1.0/token/ERC20/extensions/ERC20Burnable.sol";
import {ERC20FlashMint} from "@openzeppelin/contracts@5.1.0/token/ERC20/extensions/ERC20FlashMint.sol";
import {Ownable} from "@openzeppelin/contracts@5.1.0/access/Ownable.sol";

contract Nudex is ERC20, ERC20Burnable, Ownable, ERC20FlashMint {
    uint256 public constant MINT_FEE = 0.000071 ether; // Minting fee
    uint256 public constant TOKENS_PER_MINT = 7 * 10 ** 18; // Tokens per mint (with 18 decimals)
    uint256 public constant MAX_DAILY_SUPPLY = 4315 * 10 ** 18; // Maximum allowed daily minting
    uint256 public dailyMintedTokens; // Amount of tokens minted in the current day
    uint256 public lastMintReset; // Marks the last daily reset timestamp
    address public feeRecipient; // Address to receive the collected fees
    uint256 public lockedSupply; // Locked initial supply
    uint256 public immutable lockReleaseTime; // Timestamp when locked supply can be released

    constructor(address initialFeeRecipient)
        ERC20("7x1Eternal", "7x1")
        Ownable(msg.sender)
    {
        uint256 initialSupply = 431533 * 10 ** 18; // Initial supply
        uint256 unlockedSupply = 7001 * 10 ** 18; // Unlocked supply

        _mint(msg.sender, unlockedSupply); // Mint only 700 tokens initially
        lockedSupply = initialSupply - unlockedSupply; // Set the locked supply
        lastMintReset = block.timestamp;
        feeRecipient = initialFeeRecipient;
        lockReleaseTime = block.timestamp + 701 days; // Set lock period (701 days from deployment)
        transferOwnership(msg.sender); // Set the initial owner
    }

    function mintTokens() public payable {
        // Reset the daily counter if a new day has started
        if (block.timestamp >= lastMintReset + 1 days) {
            dailyMintedTokens = 0;
            lastMintReset = block.timestamp;
        }

        // Verify that the total and daily supply limits allow minting
        require(dailyMintedTokens + TOKENS_PER_MINT <= MAX_DAILY_SUPPLY, "Daily supply limit reached");
        require(msg.value == MINT_FEE, "Insufficient fee for minting");

        // Update the daily counter and mint tokens
        dailyMintedTokens += TOKENS_PER_MINT;
        _mint(msg.sender, TOKENS_PER_MINT);

        // Transfer the fee to the recipient
        payable(feeRecipient).transfer(msg.value);
    }

    // Function to update the fee recipient address
    function setFeeRecipient(address newRecipient) public onlyOwner {
        require(newRecipient != address(0), "Invalid address");
        feeRecipient = newRecipient;
    }

    // Function to transfer ownership of the contract
    function transferOwnership(address newOwner) public override onlyOwner {
        require(newOwner != address(0), "Invalid new owner");
        super.transferOwnership(newOwner);
    }

    // Function to release locked supply (only owner can call)
    function releaseLockedSupply(uint256 amount) public onlyOwner {
        require(block.timestamp >= lockReleaseTime, "Locked supply cannot be released yet");
        require(amount <= lockedSupply, "Amount exceeds locked supply");
        lockedSupply -= amount;
        _mint(msg.sender, amount);
    }

    // Function to view the amount of locked supply
    function viewLockedSupply() public view returns (uint256) {
        return lockedSupply;
    }
}
