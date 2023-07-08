//SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "../layoutStorage.sol";

error Diamond_NotOwnerCall(address caller);
error Diamond_NotValidFacet(string errorMsg);
error Diamond_NoSelectorsPovided();
error Diamond_SelectorAlreadyExist(bytes4 selector);
error Diamond_SelectorDoesNotExist(bytes4 selector);
error Diamond_FacetAlreadyExist(string errorMsg);
error Diamond_facetAlreadyInitialized();
error Diamond_FacetIsNotAContract();

library diamondLib {
    /// events :
    event FacetCut(address indexed facet, bytes4[] selectors);
    event Removed(bytes4[] indexed functionRemoved);
    event Add(bytes4[] selectors, address facet);
    // the position of the mainstorage in the diamond storage:

    bytes32 internal constant MAIN_STORAGE_LOCATION = bytes32(uint256(keccak256("Main.Storage.Location")) - 1);

    // create a function facetCut :

    modifier initialize() {
        mainStorage storage s = _storage();
        if (s.initialized == 1) revert Diamond_facetAlreadyInitialized();
        _;
        s.initialized = 1;
    }

    function cutFacet(facetCut calldata _facetCut) internal {
        // check that the caller is the ownership
        _checkOwnership();
        // check thta _facetCut provided is valid(not address zero and not address diamond)
        _checkFacetCut(_facetCut);
        // add facet to the storage :
        _cutFacet(_facetCut);
        emit FacetCut(_facetCut.facet, _facetCut.selectors);
    }

    // function to remove function :
    function remove(bytes4[] calldata _selectorsToRemove) internal {
        // check that the caller is ownership
        _checkOwnership();
        _remove(_selectorsToRemove);
        emit Removed(_selectorsToRemove);
    }

    //function to add anew function :
    function add(facetCut calldata _facetCut) internal {
        //chekc that the caller is the owner:
        _checkOwnership();
        _checkFacetCut(_facetCut);
        _add(_facetCut.selectors, _facetCut.facet);
        emit Add(_facetCut.selectors, _facetCut.facet);
    }

    // funciton that return the mainstorge in the slot
    function _storage() internal pure returns (mainStorage storage _mainStorage) {
        bytes32 location = MAIN_STORAGE_LOCATION;
        assembly {
            _mainStorage.slot := location
        }
    }

    ////helper functions :
    function _checkOwnership() internal view {
        mainStorage storage s = _storage();
        if (msg.sender != s.ownership) revert Diamond_NotOwnerCall(msg.sender);
    }

    function _checkFacetCut(facetCut calldata _facetCut) internal view {
        if (_facetCut.facet == address(0) || _facetCut.facet == address(this)) {
            revert Diamond_NotValidFacet("Address zero or Diamond address");
        }
        if (_facetCut.selectors.length == 0) {
            revert Diamond_NoSelectorsPovided();
        }
        if (!_isContract(_facetCut.facet)) revert Diamond_FacetIsNotAContract();
    }

    function _fallbackCheck() internal view returns (address facet) {
        mainStorage storage s = _storage();
        bytes4 selector = msg.sig;

        if (s.selectorToFacet[selector].facet == address(0)) {
            revert Diamond_SelectorDoesNotExist(selector);
        }
        facet = s.selectorToFacet[selector].facet;
    }

    function _cutFacet(facetCut calldata _facetCut) internal {
        mainStorage storage s = _storage();
        if (s.facetToSelectors[_facetCut.facet].selectors.length != 0) {
            revert Diamond_FacetAlreadyExist("You can only add or remove or replace functions from this Facet.");
        }
        for (uint256 index; index < _facetCut.selectors.length; index++) {
            bytes4 selector = _facetCut.selectors[index];
            // check that the selector do not exist
            if (s.selectorToFacet[selector].facet != address(0)) {
                revert Diamond_SelectorAlreadyExist(selector);
            }
            //add the selector postion:
            s.selectorToFacet[selector].postion = uint32(s.facetToSelectors[_facetCut.facet].selectors.length);
            // push the selector to the array of selectors :
            s.facetToSelectors[_facetCut.facet].selectors.push(selector);
        }
        s.facetToSelectors[_facetCut.facet].position = uint32(s.facets.length);
        s.facets.push(_facetCut.facet);
    }

    function _remove(bytes4[] calldata _selectors) internal {
        if (_selectors.length == 0) revert Diamond_NoSelectorsPovided();
        mainStorage storage s = _storage();
        for (uint256 index; index < _selectors.length; index++) {
            // check that the selector not exsit :
            bytes4 selector = _selectors[index];
            if (s.selectorToFacet[selector].facet == address(0)) {
                revert Diamond_SelectorDoesNotExist(selector);
            }
            //get the postion of the selector and it's facet
            address facet = s.selectorToFacet[selector].facet;
            uint32 position = s.selectorToFacet[selector].postion;

            // check if the selector is the last one in the array
            if (position != uint32(s.facetToSelectors[facet].selectors.length - 1)) {
                //set last selector in array selectors to position of selector wanna delete
                bytes4[] memory selectors = s.facetToSelectors[facet].selectors;
                uint32 lastPostion = uint32(selectors.length - 1);
                selectors[position] = selectors[lastPostion];
                s.selectorToFacet[selectors[position]].postion = position;
                s.facetToSelectors[facet].selectors = selectors;
            }
            //pop the last selector from the selectors array ,
            s.facetToSelectors[facet].selectors.pop();
            //delete the refrence from selector to array ;
            delete s.selectorToFacet[selector];

            // delete facet if it does not have selectors any more :
            if (s.facetToSelectors[facet].selectors.length == 0) {
                // if facet is not the last address in facets array
                if (facet != s.facets[s.facets.length - 1]) {
                    // get the facet position
                    uint32 facetPosition = s.facetToSelectors[facet].position;
                    address[] memory facets = s.facets;
                    facets[facetPosition] = facets[facets.length - 1];

                    // set the last facet selector to the new position
                    s.facetToSelectors[facets[facetPosition]].selectors =
                        s.facetToSelectors[facets[facets.length - 1]].selectors;
                    s.facetToSelectors[facets[facetPosition]].position = facetPosition;
                    s.facets = facets;
                }
                // pop the last address from facets array:
                s.facets.pop();
                // delete the refrence of facet :
                s.facetToSelectors[facet].position = 0;
            }
        }
    }

    function _add(bytes4[] calldata _selectors, address _facet) internal {
        mainStorage storage s = _storage();
        if (s.facetToSelectors[_facet].selectors.length == 0) {
            // add the facet :
            s.facetToSelectors[_facet].position = uint32(s.facets.length);
            s.facets.push(_facet);
        }
        for (uint256 index; index < _selectors.length; index++) {
            bytes4 selector = _selectors[index];
            if (s.selectorToFacet[selector].facet != address(0)) {
                revert Diamond_SelectorAlreadyExist(selector);
            }
            // assing selector to facet and position ;

            s.selectorToFacet[selector].facet = _facet;
            s.selectorToFacet[selector].postion = uint32(s.facetToSelectors[_facet].selectors.length);
            s.facetToSelectors[_facet].selectors.push(selector);
        }
    }

    function _init() internal initialize {
        mainStorage storage s = _storage();
        s.ownership = msg.sender;
    }

    function _isContract(address Address) internal view returns (bool) {
        uint256 codeSize;
        assembly {
            codeSize := extcodesize(Address)
        }
        return codeSize > 0;
    }
}
