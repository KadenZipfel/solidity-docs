pragma solidity >=0.4.24 <0.7.0;

contract ReceiverPays {
  address owner = msg.sender;

  mapping(uint256 => bool) usedNonces;

  constructor() public payable {}

  function claimPayment(uint256 amount, uint256 nonce, bytes memory signature)
    public
  {
    require(!usedNonces[nonce], 'Nonce value has already been used.');
    usedNonces[nonce] = true;

    bytes32 message = prefixed(keccak256(abi.encodePacked((
      msg.sender, amount, nonce, this))
    ));

    require(recoverSigner(message, signature) == owner);

    msg.sender.transfer(amount);
  }

  /// Destroy the contract and reclaim the leftover funds.
  function kill() public {
    require(msg.sender == owner);
    selfdestruct(msg.sender);
  }

  /// Signature methods.
  function splitSignature(bytes memory sig)
    internal
    pure
    returns(uint8 v, bytes32 r, bytes32 s)
  {
    require(sig.length == 65);

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
    returns (address)
  {
    (uint8 v, bytes32 r, bytes32 s) = splitSignature(sig);

    return ecrecover(message, v, r, s);
  }

  /// Builds a prefixed has to mimic the behavior of eth_sign.
  function prefixed(bytes32 hash) internal pure returns (bytes32) {
    return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hash));
  }
}