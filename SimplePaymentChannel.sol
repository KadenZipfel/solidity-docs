pragma solidity >=0.4.24 <0.7.0;

contract SimplePaymentChannel {
  address payable public sender;
  address payable public recipient;
  uint256 public expiration;

  constructor(address payable _recipient, uint256 duration)
    public
    payable
  {
    sender = msg.sender;
    recipient = _recipient;
    expiration = now + duration;
  }

  function isValidSignature(uint256 amount, bytes memory signature)
    internal
    view
    returns (bool)
  {
    bytes32 message = prefixed(keccak256(abi.encodePacked(this, amount)));

    return recoverSigner(message, signature) == sender;
  }

  /// The recipient can close the channel at any time.
  function close(uint256 amount, bytes memory signature) public {
    require(msg.sender == recipient, 'Only the recipient can do this.');
    require(isValidSignature(amount, signature), 'Signature invalid.');

    recipient.transfer(amount);
    selfdestruct(sender);
  }

  /// The sender can extend the expiration at any time.
  function extend(uint256 newExpiration) public {
    require(msg.sender == sender, 'Only the sender can do this.');
    require(newExpiration > expiration, 'You may only extend the expiration.');

    expiration = newExpiration;
  }

  /// If the timeout is reached without the recipient closing the channel,
  /// the ether is released back to the sender.
  function claimTimeout() public {
    require(now >= expiration, 'Please wait for the expiration.');
    selfdestruct(sender);
  }

  function splitSignature(bytes memory sig)
    internal
    pure
    returns (uint8 v, bytes32 r, bytes32 s)
  {
    require(sig.length == 65, 'Invalid signature.');

    assembly {
      r := mload(add(sig, 32))
      s := mload(add(sig, 64))
      v := byte(0, mload(add(sig, 96)))
    }

    return(v, r, s);
  }

  function recoverSigner(bytes32 message, bytes memory sig)
    internal
    pure
    returns(address)
  {
    (uint8 v, bytes32 r, bytes32 s) = splitSignature(sig);

    return ecrecover(message, v, r, s);
  }

  function prefixed(bytes32 hash) internal pure returns (bytes32) {
    return keccak256(abi.encodePacked('\x19Ethereum Signed Message:\n32', hash));
  }
}