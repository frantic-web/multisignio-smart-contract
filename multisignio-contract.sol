pragma solidity ^0.4.19;


/**
 * @title Multisignio Contract
 * @author Alex 'AL_X' Papageorgiou
 * @dev The MSG ERC-20 & ERC-223 Compliant Token Contract
 */
contract Multisignio {
    string public name = "Multisignio";
    string public symbol = "MSG";
    address public admin;
    uint8 public decimals = 16;
    uint256 public totalFunds;
    uint256 public totalSupply = 270000000*(10**16);
    uint256 public tokenSaleDate;
    uint256 public transparentCost;
    uint256 public liteCost;
    uint256 public availableFreeWallets;
    uint256 public airdropTokens;
    uint256 private decimalMultiplier = 10**16;
    bool private running;
    mapping(address => uint256) balances;
    mapping(address => mapping (address => uint256)) allowed;
    mapping(address => bool) freeWallet;
    mapping(address => bool) airdropClaimed;
    mapping(address => bool) whitelisted;

    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
    event WalletCreation(address indexed _owner, uint256 _type, bytes32 _partialSeed);

    /**
     * @notice Ensures admin is caller
     */
    modifier isAdmin() {
        require(msg.sender == admin);
        _;
    }

    /**
    * @notice Re-entry protection
    */
    modifier isRunning() {
        require(!running);
        running = true;
        _;
        running = false;
    }

    /**
     * @notice SafeMath Library safeSub Import
     * @dev
            Since we are dealing with a limited currency
            circulation of 270 million tokens and values
            that will not surpass the uint256 limit, only
            safeSub is required to prevent underflows.
    */
    function safeSub(uint256 a, uint256 b) internal pure returns (uint256 z) {
        assert((z = a - b) <= a);
    }
    /**
     * @notice MSG Constructor
     * @dev
            Normal constructor function, 94m tokens
            on sale during the ICO, 1m tokens for
            bounties & 5m tokens for the developers.
    */
    function Multisignio() public {
        admin = msg.sender;
        balances[msg.sender] = 66000000*decimalMultiplier;
        airdropTokens = 4000000*decimalMultiplier;
        balances[this] = 200000000*decimalMultiplier;
        tokenSaleDate = ~uint256(0);
        liteCost = 1200*decimalMultiplier;
        transparentCost = liteCost*10;
        availableFreeWallets = 10000;
    }

    /**
     * @notice Check the name of the token ~ ERC-20 Standard
     * @return {
                    "_name": "The token name"
                }
     */
    function name() external constant returns (string _name) {
        return name;
    }

    /**
     * @notice Check the symbol of the token ~ ERC-20 Standard
     * @return {
                    "_symbol": "The token symbol"
                }
     */
    function symbol() external constant returns (string _symbol) {
        return symbol;
    }

    /**
     * @notice Check the decimals of the token ~ ERC-20 Standard
     * @return {
                    "_decimals": "The token decimals"
                }
     */
    function decimals() external constant returns (uint8 _decimals) {
        return decimals;
    }

    /**
     * @notice Check the total supply of the token ~ ERC-20 Standard
     * @return {
                    "_totalSupply": "Total supply of tokens"
                }
     */
    function totalSupply() external constant returns (uint256 _totalSupply) {
        return totalSupply;
    }

    /**
     * @notice Query the available balance of an address ~ ERC-20 Standard
     * @param _owner The address whose balance we wish to retrieve
     * @return {
                    "balance": "Balance of the address"
                }
     */
    function balanceOf(address _owner) external constant returns (uint256 balance) {
        return balances[_owner];
    }
    /**
     * @notice Query the amount of tokens the spender address can withdraw from the owner address ~ ERC-20 Standard
     * @param _owner The address who owns the tokens
     * @param _spender The address who can withdraw the tokens
     * @return {
                    "remaining": "Remaining withdrawal amount"
                }
     */
    function allowance(address _owner, address _spender) external constant returns (uint256 remaining) {
        return allowed[_owner][_spender];
    }

    /**
     * @notice Transfer tokens from an address to another ~ ERC-20 Standard
     * @param _from The address whose balance we will transfer
     * @param _to The recipient address
     * @param _value The amount of tokens to be transferred
     */
    function transferFrom(address _from, address _to, uint256 _value) external {
        var _allowance = allowed[_from][_to];
        balances[_to] = balances[_to]+_value;
        balances[_from] = safeSub(balances[_from], _value);
        allowed[_from][_to] = safeSub(_allowance, _value);
        Transfer(_from, _to, _value);
    }

    /**
     * @notice Authorize an address to retrieve funds from you ~ ERC-20 Standard
     * @dev
            Each approval comes with a default cooldown of 30 minutes
            to prevent against the ERC-20 race attack.
     * @param _spender The address you wish to authorize
     * @param _value The amount of tokens you wish to authorize
     */
    function approve(address _spender, uint256 _value) external {
        allowed[msg.sender][_spender] = _value;
        Approval(msg.sender, _spender, _value);
    }

    /**
     * @notice Transfer the specified amount to the target address ~ ERC-20 Standard
     * @dev
            A boolean is returned so that callers of the function
            will know if their transaction went through.
     * @param _to The address you wish to send the tokens to
     * @param _value The amount of tokens you wish to send
     * @return {
                    "success": "Transaction success"
                }
     */
    function transfer(address _to, uint256 _value) external isRunning returns (bool success){
        bytes memory empty;
        if (_to == address(this)) {
            revert();
        } else if (isContract(_to)) {
            return transferToContract(_to, _value, empty);
        } else {
            return transferToAddress(_to, _value, empty);
        }
    }

    /**
     * @notice Check whether address is a contract ~ ERC-223 Proposed Standard
     * @param _address The address to check
     * @return {
                    "is_contract": "Result of query"
                }
     */
    function isContract(address _address) internal view returns (bool is_contract) {
        uint length;
        assembly {
            length := extcodesize(_address)
        }
        return length > 0;
    }

    /**
     * @notice Transfer the specified amount to the target address with embedded bytes data ~ ERC-223 Proposed Standard
     * @dev Includes an extra buyWallet function to handle wallet purchases
     * @param _to The address to transfer to
     * @param _value The amount of tokens to transfer
     * @param _data Any extra embedded data of the transaction
     * @return {
                    "success": "Transaction success"
                }
     */
    function transfer(address _to, uint256 _value, bytes _data) external isRunning returns (bool success) {
        if (_to == address(this)) {
            revert();
        } else if (isContract(_to)) {
            return transferToContract(_to, _value, _data);
        } else {
            return transferToAddress(_to, _value, _data);
        }
    }

    /**
     * @notice Handles transfer to an ECA (Externally Controlled Account), a normal account ~ ERC-223 Proposed Standard
     * @param _to The address to transfer to
     * @param _value The amount of tokens to transfer
     * @param _data Any extra embedded data of the transaction
     * @return {
                    "success": "Transaction success"
                }
     */
    function transferToAddress(address _to, uint256 _value, bytes _data) internal returns (bool success) {
        balances[msg.sender] = safeSub(balances[msg.sender], _value);
        balances[_to] = balances[_to]+_value;
        Transfer(msg.sender, _to, _value);
        return true;
    }

    /**
     * @notice Handles transfer to a contract ~ ERC-223 Proposed Standard
     * @param _to The address to transfer to
     * @param _value The amount of tokens to transfer
     * @param _data Any extra embedded data of the transaction
     * @return {
                    "success": "Transaction success"
                }
     */
    function transferToContract(address _to, uint256 _value, bytes _data) internal returns (bool success) {
        balances[msg.sender] = safeSub(balances[msg.sender], _value);
        balances[_to] = balances[_to]+_value;
        Multisignio rec = Multisignio(_to);
        rec.tokenFallback(msg.sender, _value, _data);
        Transfer(msg.sender, _to, _value);
        return true;
    }

    /**
     * @notice Empty tokenFallback method to ensure ERC-223 compatibility
     * @param _sender The address who sent the ERC-223 tokens
     * @param _value The amount of tokens the address sent to this contract
     * @param _data Any embedded data of the transaction
     */
    function tokenFallback(address _sender, uint256 _value, bytes _data) public {}

    /**
     * @notice Retrieve ERC Tokens sent to contract
     * @dev Feel free to contact us and retrieve your ERC tokens should you wish so.
     * @param _token The token contract address
     */
    function claimTokens(address _token) isAdmin external {
        require(_token != address(this));
        Multisignio token = Multisignio(_token);
        uint balance = token.balanceOf(this);
        token.transfer(admin, balance);
    }

    /**
     * @notice Fallback function
     * @dev Triggered when Ether is sent to the contract.
     */
    function() payable external {
        require(msg.value > 0);
        require(now > tokenSaleDate);
        if (now > tokenSaleDate) {
            uint256 tokenAmount;
            tokenAmount = tokenMultiplier(msg.value);
            balances[msg.sender] += tokenAmount;
            balances[this] = safeSub(balances[this],tokenAmount);
            totalFunds += msg.value;
            Transfer(this, msg.sender, tokenAmount);
            admin.transfer(msg.value);
        } else if (tokenSaleDate == ~uint256(0)) {
            require(whitelisted[msg.sender] && msg.value > 2*decimalMultiplier*(10**2));
            tokenAmount = 150*msg.value;
            balances[msg.sender] += tokenAmount;
            balances[this] = safeSub(balances[this],tokenAmount);
            totalFunds += msg.value;
            Transfer(this, msg.sender, tokenAmount);
            admin.transfer(msg.value);
        } else {
            revert();
        }
    }

    /**
     * @notice Token Multiplier getter
     * @dev The token price adjustes based on both demand & a time-based sale
     */
    function tokenMultiplier(uint256 etherSent) public view returns (uint256) {
        // if (now < tokenSaleDate + 1 days && (200000000*decimalMultiplier - balances[this]) <= 20000000*decimalMultiplier) {
        //     require(whitelisted[msg.sender] && etherSent > 2*decimalMultiplier*(10**2));
        //     return 150*etherSent;
        // } else
        if (now < tokenSaleDate + 7 days && (200000000*decimalMultiplier - balances[this]) <= 60000000*decimalMultiplier) {
            return 100*etherSent;
        } else if (now < tokenSaleDate + 14 days && (200000000*decimalMultiplier - balances[this]) <= 100000000*decimalMultiplier) {
            return 75*etherSent;
        } else if (now < tokenSaleDate + 21 days && (200000000*decimalMultiplier - balances[this]) <= 140000000*decimalMultiplier) {
            return 50*etherSent;
        } else {
            return 30*etherSent;
        }
    }

    /**
     * @notice Burning function
     * @dev Burns any leftover crowdfunding tokens to ensure a proper value is
     *      set in the crypto market cap.
     */
    function burnLeftovers() external {
        require(tokenSaleDate + 30 days < now && balances[this] > 0);
        totalSupply -= balances[this];
        balances[this] = 0;
        tokenSaleDate = ~uint256(0) - 1;
    }

    /**
     * @notice Wallet Creation function
     * @dev Creates a wallet based on the input seed as far as the necessary token amount has been sent
     * @param _value Amount correlating to the wallet type
     * @param _seed The string to base the wallet creation on
     */
    function buyWallet(uint256 _value, bytes32 _seed) public returns (bool success) {
        if (_value == transparentCost) {
            balances[msg.sender] = safeSub(balances[msg.sender], transparentCost);
            balances[this] += transparentCost;
            if (freeWallet[msg.sender]) {
                availableFreeWallets++;
                freeWallet[msg.sender] = false;
            }
            WalletCreation(msg.sender, transparentCost, _seed);
            Transfer(msg.sender, this, transparentCost);
            return true;
        } else if (_value == liteCost) {
            balances[msg.sender] = safeSub(balances[msg.sender], liteCost);
            balances[this] += liteCost;
            if (freeWallet[msg.sender]) {
                availableFreeWallets++;
                freeWallet[msg.sender] = false;
            }
            WalletCreation(msg.sender, liteCost, _seed);
            Transfer(msg.sender, this, liteCost);
            return true;
        } else if (_value == 0) {
            require(availableFreeWallets >= 1);
            require(!freeWallet[msg.sender]);
            availableFreeWallets--;
            freeWallet[msg.sender] = true;
            WalletCreation(msg.sender, 0, _seed);
            return true;
        } else {
            revert();
        }
    }

    /**
     * @notice Token Sale Initiation
     * @dev Begins the token sale on the date this function is called
     */
    function beginSale() external isAdmin {
        require(tokenSaleDate == ~uint256(0));
        tokenSaleDate = now;
    }

    /**
     * @notice Wallet Price Adjustment
     * @dev Function to adjust prices based on current token market price
     */
    function adjustWalletPrices(uint256 _liteCost) external isAdmin {
        liteCost = _liteCost*decimalMultiplier;
        transparentCost = liteCost*10;
    }

    /**
     * @notice Airdrop Function
     * @dev Function to claim 1000 tokens from the AirDrop
     */
    function claimAirdropTokens() external {
        require(!airdropClaimed[msg.sender]);
        airdropClaimed[msg.sender] = true;
        balances[msg.sender] += 1000*decimalMultiplier;
        airdropTokens = safeSub(airdropTokens, 1000*decimalMultiplier);
        Transfer(this, msg.sender, 1000*decimalMultiplier);
    }

    /**
     * @notice Whitelist Function
     * @dev Function to whitelist addresses for the 1 day presale
     * @param toWhitelist Address to add to whitelist
     */
    function whitelistAddress(address toWhitelist) external isAdmin {
        whitelisted[toWhitelist] = true;
    }
}
