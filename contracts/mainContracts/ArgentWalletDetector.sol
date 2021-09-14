// SPDX-License-Identifier: GPL-2.0-or-later

pragma solidity >=0.6.12;

import '../libraries/Owned.sol';
import '../interface/IArgentProxy.sol';

/**
 * @title ArgentWalletDetector
 * @notice Simple contract to detect if a given address represents an Argent wallet.
 * The `isArgentWallet` method returns true if the codehash matches one of the deployed Proxy
 * and if the target implementation matches one of the deployed BaseWallet.
 * Only the owner of the contract can add code hash ad implementations.
 * @author Julien Niset - <julien@argent.xyz>
 */
contract ArgentWalletDetector is Owned {
	
	// The accepeted code hash
	bytes32[] private codes;
	// The accepted implementations
	address[] private implementations;
	// mapping to efficiently check if a code is accepeted
    mapping (bytes32 => Info) public acceptedCodes;
	// mapping to efficiently check is an implementation is accepeted
	mapping (address => Info) public acceptedImplementations;

	struct Info {
        bool exists;
        uint128 index;
    }

	// emits when a new accepeted code is added
	event CodeAdded(bytes32 indexed code);
	// emits when a new accepeted implementation is added 
	event ImplementationAdded(address indexed implementation);

	constructor(bytes32[] memory _codes, address[] memory _implementations) public {
		for(uint i = 0; i < _codes.length; i++) {
			addCode(_codes[i]);
		}
		for(uint j = 0; j < _implementations.length; j++) {
			addImplementation(_implementations[j]);
		}
	}

	/**
    * @notice Adds a new acceted code hash.
    * @param _code The new code hash.
    */
	function addCode(bytes32 _code) public onlyOwner {
        require(_code != bytes32(0), "AWR: empty _code");
        Info storage code = acceptedCodes[_code];
		if(!code.exists) {
			codes.push(_code);
			code.exists = true;
        	code.index = uint128(codes.length - 1);
			emit CodeAdded(_code);
		}
    }
	
	/**
    * @notice Adds a new acceted implementation.
    * @param _impl The new implementation.
    */
	function addImplementation(address _impl) public onlyOwner {
        require(_impl != address(0), "AWR: empty _impl");
        Info storage impl = acceptedImplementations[_impl];
		if(!impl.exists) {
			implementations.push(_impl);
			impl.exists = true;
        	impl.index = uint128(implementations.length - 1);
			emit ImplementationAdded(_impl);
		}
    }

	/**
    * @notice Adds a new acceted code hash and implementation from a deployed Argent wallet.
    * @param _argentWallet The deployed Argent wallet.
    */
    function addCodeAndImplementationFromWallet(address _argentWallet) external onlyOwner {
        bytes32 codeHash;   
    	assembly { codeHash := extcodehash(_argentWallet) }
        addCode(codeHash);
        address implementation = IArgentProxy(_argentWallet).implementation(); 
        addImplementation(implementation);
    }

	/**
    * @notice Gets the list of accepted implementations.
    */
	function getImplementations() public view returns (address[] memory) {
		return implementations;
	}

	/**
    * @notice Gets the list of accepted code hash.
    */
	function getCodes() public view returns (bytes32[] memory) {
		return codes;
	}

	/**
    * @notice Checks if an address is an Argent wallet
	* @param _wallet The target wallet
    */
	function isArgentWallet(address _wallet) external view returns (bool) {
		bytes32 codeHash;    
    	assembly { codeHash := extcodehash(_wallet) }
		return acceptedCodes[codeHash].exists && acceptedImplementations[IArgentProxy(_wallet).implementation()].exists;
	}
}