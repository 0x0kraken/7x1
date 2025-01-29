// SPDX-License-Identifier: MIT
pragma solidity ^0.8.22;

import {ERC20} from "@openzeppelin/contracts@5.1.0/token/ERC20/ERC20.sol";
import {ERC20Burnable} from "@openzeppelin/contracts@5.1.0/token/ERC20/extensions/ERC20Burnable.sol";
import {ERC20FlashMint} from "@openzeppelin/contracts@5.1.0/token/ERC20/extensions/ERC20FlashMint.sol";
import {Ownable} from "@openzeppelin/contracts@5.1.0/access/Ownable.sol";

contract Nudex is ERC20, ERC20Burnable, Ownable, ERC20FlashMint {
    uint256 public constant MINT_FEE = 0.00007 ether; // Taxa por mint
    uint256 public constant TOKENS_PER_MINT = 7 * 10 ** 18; // Tokens por mint (com 18 decimais)
    uint256 public constant MAX_SUPPLY = 431533233 * 10 ** 18; // Fornecimento total (com 18 decimais)
    uint256 public constant MAX_SUPPLY_DIARIO = 4315 * 10 ** 18; // Máximo permitido para mint diário
    uint256 public dailyMintedTokens; // Quantidade de tokens mintados no dia
    uint256 public lastMintReset; // Marca o último reset diário

    address public feeRecipient; // Endereço que receberá as taxas

    constructor(address initialOwner, address initialFeeRecipient)
        ERC20("7x1Eternal", "7x1")
        Ownable()
    {
        uint256 initialSupply = 431533 * 10 ** 18; // Fornecimento inicial
        _mint(msg.sender, initialSupply);
        lastMintReset = block.timestamp;
        feeRecipient = initialFeeRecipient;
        transferOwnership(initialOwner); // Define o proprietário inicial
    }

    function mintTokens() public payable {
        // Reseta o contador diário se um novo dia começar
        if (block.timestamp >= lastMintReset + 1 days) {
            dailyMintedTokens = 0;
            lastMintReset = block.timestamp;
        }

        // Verifica se o fornecimento total e o diário permitem o mint
        require(totalSupply() + TOKENS_PER_MINT <= MAX_SUPPLY, "Fornecimento total atingido");
        require(dailyMintedTokens + TOKENS_PER_MINT <= MAX_SUPPLY_DIARIO, "Fornecimento diario atingido");
        require(msg.value == MINT_FEE, "Saldo insuficiente para mintar");

        // Atualiza o contador diário e minta os tokens
        dailyMintedTokens += TOKENS_PER_MINT;
        _mint(msg.sender, TOKENS_PER_MINT);

        // Envia a taxa para o destinatário
        payable(feeRecipient).transfer(msg.value);
    }

    // Função para alterar o destinatário das taxas
    function setFeeRecipient(address newRecipient) public onlyOwner {
        require(newRecipient != address(0), "Endereço inválido");
        feeRecipient = newRecipient;
    }

    // Função para alterar o proprietário do contrato
    function transferOwnership(address newOwner) public override onlyOwner {
        require(newOwner != address(0), "Novo proprietário inválido");
        super.transferOwnership(newOwner);
    }
}
