pragma solidity >=0.4.22 <0.7.0;

contract Purchase {
  uint public value;
  address payable public seller;
  address payable public buyer;
  enum State { Created, Locked, Inactive }
  State public state;

  constructor() public payable {
    seller = msg.sender;
    value = msg.value / 2;
    require((2 * value) == msg.value, 'Value has to be an even number.');
  }

  modifier condition(bool _condition) {
    require(_condition);
    _;
  }

  modifier onlyBuyer() {
    require(
      msg.sender == buyer,
      'Only the buyer can call this.'
    );
    _;
  }

  modifier onlySeller() {
    require(
      msg.sender == seller,
      'Only the seller can call this.'
    );
    _;
  }

  modifier inState(State _state) {
    require(
      state == _state,
      'Invalid state.'
    );
    _;
  }

  event Aborted();
  event PurchaseConfirmed();
  event ItemReceived();

  /// Abort the purchase and reclaim the ether.
  /// Can only be called by the seller before
  /// the contract is locked.
  function abort()
    public
    onlySeller
    inState(State.Created)
  {
    emit Aborted();
    state = State.Inactive;
    seller.transfer(address(this).balance);
  }

  /// Confirm the purchase as buyer.
  /// Transaction has to include `2 * value` ether.
  /// The ether will be locked until confirmReceived
  /// is called.
  function confirmPurchase()
    public
    inState(State.Created)
    condition(msg.value == (2 * value))
    payable
  {
    emit PurchaseConfirmed();
    buyer = msg.sender;
    state = State.Locked;
  }

  /// Confirm that you (the buyer) received the item.
  /// This will release the locked ether.
  function confirmReceived()
    public
    onlyBuyer
    inState(State.Locked)
  {
    emit ItemReceived();
    state = State.Inactive;

    buyer.transfer(value);
    seller.transfer(address(this).balance);
  }
}