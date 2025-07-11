// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IERC20{

    function transfer(address recipient, uint256 amount) external returns (bool);

    function balanceOf(address account) external view returns (uint256);

    function symbol() external view returns (string memory);

    function totalSupply() external view returns (uint256);

    function name() external view returns (string memory);
}

contract ICOMarket{

    struct TokenDetails{
        address token;
        bool supported;
        uint256 price;
        address creator;
        string name;
        string symbol;
    }

    //MAPPING
    mapping(address => TokenDetails) public tokenDetails;
    address[] public allSupportedTokens;
    address public owner;


    //EVENTS
    event TokenRecieved(address indexed token, address indexed from, uint256 amount);
    event TokenTransferred(address indexed token, address indexed to, uint256 amount);
    event TokenWidthdraw(address indexed token, address indexed to, uint256 amount);
    event TokenAdded(address indexed token, uint256 price, address indexed creator,
    string name, string symbol);

    //MODIFIERS
    modifier supportedToken(address _token){
        require(tokenDetails[_token].supported, "Token not Supported");
        _;
    };

    modifier onlyOwner(){
        require(msg.sender == owner, "Caller is not Owner");
        _;
    };

    modifier onlyCreator(address _token ){
        require(msg.sender == tokenDetails[_token].creator, "Caller is not token");
        _;
    };

    receive() external payable{
        revert("Direct ETH transfers not allowed");
    };

    constructor(){
        owner = msg.sender;
    };


    //CONTRACT FUNCTIONS
    function createICOSale(address _token, uint256 _price) external {
        IERC20 token = IERC20(_token);
        string memory tokenName = token.name();
        string memory tokenSymbol = token.symbol();

        tokenDetails[_token] = TokenDetails({
            token: _token,
            supported: true,
            price: _price,
            creator: msg.sender,
            name: tokenName,
            symbol: tokenSymbol
        });

        allSupportedTokens.push(_token);

        emit TokenAdded(_token, _price, msg.sender, tokenName, tokenSymbol);

    };

    function multiply(uint256 x, uint256 y) internal pure returns(uint256 z){

        require(y==0 || (z = x * y) / y == x, "Multiplication overflow");
    };

    function buyToken(address _token, uint256 _amount) external payable supportedToken(_token){

        require(_amount > 0, "Amount must be greater than zero");

        TokenDetails memory details = tokenDetails[_token];
        uint256 totalCost = multiply(details.price, _amount);
        require(msg.value >= totalCost, "Insufficient ETH sent");

        //Transfer of payment to the token creator
        (bool success, ) = details.creator.call{value:  totalCost}("");

        require(success, "Payment transfer to the creator failed");

        IERC20 token = IERC20(_token);
        require(token.transfer(msg.sender, _amount * 10**18), "Token transfer failed");

        emit TokenTransferred(_token, msg.sender, _amount);
    };

    function getBalance(address _token) external view returns(uint256){
        require(tokenDetails[_token].supported, "Token not supported");
        IERC20 token = IERC20(_token);
        return token.balanceOf(address(this));
    };

    function getSupportedToken() external view returns(address[] memory){
        return allSupportedTokens;
    };

    function widthdrawToken(address _token, _amount ) external onlyCreator(_token)
    supportedToken(_token){
        require(_amount > 0, "Amount must be greater than zero");
        IERC20 token = IERC20(_token);
        uint256 contractBalance = token.balanceOf(address(this));
        require(contractBalance >= _amount, "Insufficient contract balance");

        require(token.transfer(msg.sender, _amount), "Token transfer failed");

        emit TokenWidthdraw(_token, msg.sender, _amount);


    };

    function getTokenDetails(address _token) external view returns(TokenDetails memory){
        require(tokenDetails[_token].supported, "Token not supported");
        return tokenDetails[_token];
    };

    function getTokenCreatedBy(address _creator) external view returns(TokenDetails[]
    memory){
        uint256 count = 0;
        for (uint256 i = 0; i < allSupportedTokens.length; i++) {
            if (tokenDetails[allSupportedTokens[i]].creator == _creator) {
                count++;
            }
        }

        TokenDetails[] memory tokensByCreator = new TokenDetails[](count);
        uint256 index = 0;

        for (uint256 i = 0; i < allSupportedTokens.length; i++) {
            if (tokenDetails[allSupportedTokens[i]].creator == _creator) {
                tokensByCreator[index] = tokenDetails[allSupportedTokens[i]];
                index++;
            }
        }

        return tokensByCreator;
    };

    function getAllTokens() external view returns(TokenDetails[] memory){
        
        TokenDetails[] memory allTokens = new TokenDetails[](allSupportedTokens.length);
        for (uint256 i = 0; i < allSupportedTokens.length; i++) {
            allTokens[i] = tokenDetails[allSupportedTokens[i]];
        }
        return allTokens;
    };






}