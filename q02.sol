pragma solidity >= 0.7.0 < 0.8.0;

contract MyToken {
    string public name;
    string public symbol;
    uint256 public decimals;
    uint256 public totalSupply;
    mapping (address => uint256) public balanceOf;
    mapping (address => int8) public blackList;
    mapping (address => int8) public cashbackRate;
    address public owner;
    
    modifier onlyOwner() { require(msg.sender == owner); _; }
    
    constructor(string memory _name, string memory _symbol, uint256 _supply, uint256 _decimals) {
        name = _name;
        symbol = _symbol;
        decimals = _decimals;
        balanceOf[msg.sender] = _supply * 10 ** decimals;
        totalSupply = _supply * 10 ** decimals;
        owner = msg.sender;
    }
    
    function blacklisting(address _addr) onlyOwner public {
        blackList[_addr] = 1;
    }
    
    function deleteFromBlacklist(address _addr) onlyOwner public {
        blackList[_addr] = 0;
    }
    
    function setCashbackRate(int8 _rate) public {
        if (_rate < 1) { _rate = 0; }
        else if (_rate > 100) { _rate = 100; }
        
        cashbackRate[msg.sender] = _rate;
    }
    
    function transfer(address _to, uint256 _value) public {
        if (balanceOf[msg.sender] < _value) { revert(); }
        if (balanceOf[_to] + _value < balanceOf[_to]) { revert(); }
        
        if (blackList[msg.sender] > 0) { revert(); }
        else if (blackList[_to] > 0) { revert(); }
        else {
            uint256 cashback = 0;
            if (cashbackRate[_to] > 0) {
                cashback = uint256(cashbackRate[_to]) * (_value / 100);
            }
            
            balanceOf[msg.sender] -= (_value - cashback);
            balanceOf[_to] += (_value - cashback);
        }
    }
}

contract TokenVendor {
    uint256 internal startTime;
    uint256 internal deadline;
    uint256 public pricePerToken;
    uint256 public salesVolume;
    uint256 internal soldToken;
    MyToken public token;
    bool public isOpened;
    address public owner;
    
    modifier onlyOwner() { if (msg.sender != owner) revert(); _; }
    
    constructor(MyToken _tokenAddr, uint256 _salesVolume, uint256 _amountOfTokenPerEther) {
        owner = msg.sender;
        token = MyToken(_tokenAddr);
        salesVolume = _salesVolume;
        
        // TO DO: set price per token //
        pricePerToken = 1 ether / _amountOfTokenPerEther;
    }
    
    function buy() public payable {
        require(isOpened && block.timestamp < deadline);
        uint256 tokenAmount = msg.value / pricePerToken;
        require(tokenAmount > 0 && soldToken + tokenAmount <= salesVolume);
        
        // TO DO: send token and calulate how many tokens have been sold //
        token.transfer(msg.sender, tokenAmount);
        soldToken += tokenAmount;
    }
    
    function start(uint256 _durationInMinutes) public onlyOwner {
        require(address(token) != address(0) && salesVolume > 0 && token.balanceOf(address(this)) >= salesVolume);
        require(_durationInMinutes > 0 && startTime == 0);
        
        startTime = block.timestamp;
        deadline = block.timestamp + _durationInMinutes * 1 minutes;
        isOpened = true;
    }
    
    function close() public onlyOwner {
        require(isOpened);
        require(salesVolume == soldToken || block.timestamp >= deadline);
        isOpened = false;
    }
    
    function getRemainingTimeToken() public view returns(uint min, uint remainingToken) {
        if (block.timestamp < deadline) {
            min = (deadline - block.timestamp) / 1 minutes;
        }
        
        remainingToken = salesVolume - soldToken;
        
    }
    
    function withdraw() public onlyOwner {
        require(!isOpened);
        uint sales = address(this).balance;
        
        // send ethers to token distributor //
        payable(msg.sender).send(sales);
        
        uint remainingToken = token.balanceOf(address(this));
        
        // send remaining tokens to token distributor //
        token.transfer(msg.sender, remainingToken);
    }
    
}