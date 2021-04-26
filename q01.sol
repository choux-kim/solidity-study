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
        // (a) //
        owner = msg.sender;
    }
    
    // (b) //
    function blacklisting(address _addr) onlyOwner public {
        blackList[_addr] = 1;
    }
    
    // (b) //
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
        
        // (c) //
        if (blackList[msg.sender] > 0) { revert(); }
        
        // (c) //
        else if (blackList[_to] > 0) { revert(); }
        
        else {
            uint256 cashback = 0;
            if (cashbackRate[_to] > 0) {
                // (d) //
                cashback = uint256(cashbackRate[_to]) * (_value / 100);
            }
            
            balanceOf[msg.sender] -= (_value - cashback);
            balanceOf[_to] += (_value - cashback);
        }
    }
}