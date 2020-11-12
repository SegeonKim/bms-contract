pragma solidity ^0.5.0;

import "@openzeppelin/upgrades/contracts/Initializable.sol";
import "@openzeppelin/contracts-ethereum-package/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts-ethereum-package/contracts/token/ERC721/ERC721Enumerable.sol";
import "@openzeppelin/contracts-ethereum-package/contracts/token/ERC721/ERC721Metadata.sol";
import "@openzeppelin/contracts-ethereum-package/contracts/token/ERC721/ERC721MetadataMintable.sol";

contract BatteryOwnershipService is Initializable, ERC721, ERC721Enumerable, ERC721MetadataMintable {

    address public manager;
    
    struct Battery {
        uint256 batteryId; 
        //address owner; 
        bytes32 certificateHash;
        uint256 certificateId; 
        uint256 creationDt; 
        string modelName;
        string manufacturer;
        string productionDate;
        bool isActive;
    }
    
    struct Certificate {
        uint256 batteryId;
        uint256 certificateId;
		string  grade;
		string  evaluationDate;
		string  evaluationInstitute;
		bool    isLatest;
    }

    mapping(uint256 => Battery) private batteries;
    
    mapping(uint256 => mapping(uint256 => Certificate)) private certificates;
    mapping(uint256 => uint256[]) private certificateList;
    
    modifier onlyManager() {
        require(manager == msg.sender, "You are not manager.");
        _;
    }
    
    modifier onlyBatteryOwner(uint256 _batteryId) {
        require(isBatteryOwner(_batteryId, msg.sender), "You are not battery owner.");
        _;
    }
    /*
    modifier batteryExists(uint256 _batteryId) {
        require(batteries[_batteryId].isActive == true, "Battery does not exist.");
        _;
    }
    */
    event CreateOwnership (
      address   indexed owner,
      uint256   batteryId,
      //string    documentURI
      string    modelName, 
      string    manufacturer, 
      string    productionDate
    );
    
    event SaveCertificateHash (
      uint256   batteryId, 
      bytes32   certificateHash,
      uint256   certificateId,
      string    grade,
	  string    evaluationDate,
	  string    evaluationInstitute
    );
    
    event DeleteOwnership (
      address   indexed owner,
      uint256   batteryId
    );

    function initialize(string memory name, string memory symbol) public initializer {
        manager = msg.sender;

        ERC721.initialize();
        ERC721Enumerable.initialize();
        ERC721Metadata.initialize(name, symbol);
        ERC721MetadataMintable.initialize(address(this));

        _removeMinter(address(this));
    }
    
    function createOwnership (
        uint256 _batteryId,
        //string memory _documentURI 
        address _owner,
        string memory _modelName,
        string memory _manufacturer,
        string memory _productionDate
    ) public onlyManager {
        require(batteries[_batteryId].isActive == false, "Battery ID exists.");
        //require(bytes(_modelName).length > 0, "Invalid input parameters.");
        //require(_owner != address(0), "Invalid owner address.");
        
        batteries[_batteryId].batteryId = _batteryId;
        //batteries[_batteryId].owner = _owner;
        batteries[_batteryId].creationDt = block.timestamp;
        batteries[_batteryId].modelName = _modelName;
        batteries[_batteryId].manufacturer = _manufacturer;
        batteries[_batteryId].productionDate = _productionDate;
        batteries[_batteryId].isActive = true;

        // ERC-721 : mint
        _mint(_owner, _batteryId);
        //if(bytes(_documentURI).length > 0) {
        //    _setTokenURI(_batteryId, _documentURI);
        //}
        
        emit CreateOwnership(_owner, _batteryId, _modelName, _manufacturer, _productionDate);
    }
    
    function saveCertificateHash(
        uint256 _batteryId, 
        bytes32 _certificateHash,
        uint256 _certificateId,
        string memory _grade,
		string memory _evaluationDate,
		string memory _evaluationInstitute
    ) public onlyManager {
        //require(batteries[_batteryId].isActive == true, "Battery does not exist.");
        require(isBatteryExist(_batteryId), "Battery does not exist.");
        
        batteries[_batteryId].certificateHash = _certificateHash;
        batteries[_batteryId].certificateId = _certificateId;
        
        certificates[_batteryId][_certificateId].batteryId = _batteryId;
        certificates[_batteryId][_certificateId].certificateId = _certificateId;
	    certificates[_batteryId][_certificateId].grade = _grade;
        certificates[_batteryId][_certificateId].evaluationDate = _evaluationDate;
        certificates[_batteryId][_certificateId].evaluationInstitute = _evaluationInstitute;
		certificates[_batteryId][_certificateId].grade = _grade;
        certificates[_batteryId][_certificateId].isLatest = true;
        
		for (uint i = 0;i < certificateList[_batteryId].length;i++) {
            if (certificates[_batteryId][certificateList[_batteryId][i]].isLatest == true)
                certificates[_batteryId][certificateList[_batteryId][i]].isLatest = false;
        }
        certificateList[_batteryId].push(_certificateId);
        
        emit SaveCertificateHash(_batteryId, _certificateHash, _certificateId, _grade, _evaluationDate, _evaluationInstitute);
    }
    
    function validateCertificateHash(uint256 _batteryId, bytes32 _certificateHash) public view returns(bool)  {
        //require(batteries[_batteryId].isActive == true, "Battery does not exist.");
        require(isBatteryExist(_batteryId), "Battery does not exist.");
        
        return (batteries[_batteryId].certificateHash == _certificateHash);
    }
    /*
    function transferOwnership(address _from, address _to, uint256 _batteryId) public onlyBatteryOwner(_batteryId) {
        //require(batteries[_batteryId].isActive == true, "Battery does not exist.");
        require(isBatteryExist(_batteryId), "Battery does not exist.");
        
        batteries[_batteryId].owner = _to;
        
        // ERC-721 : transfer
        transferFrom(_from, _to, _batteryId);
    } 
    */
    function deleteOwnership(uint256 _batteryId) public onlyBatteryOwner(_batteryId) {
        //require(batteries[_batteryId].isActive == true, "Battery does not exist.");
        require(isBatteryExist(_batteryId), "Battery does not exist.");
        
        for (uint i = 0; i < certificateList[_batteryId].length; i++) {
            delete certificates[_batteryId][certificateList[_batteryId][i]];
        }
        delete certificateList[_batteryId];
        
        delete batteries[_batteryId];

        // ERC-721 : burn
        _burn(_batteryId);
        
         emit DeleteOwnership(msg.sender, _batteryId);
    }

    function getBatteryInfo(uint256 _batteryId)
        public
        view
        returns (
            uint256 batteryId, 
            address owner, 
            bytes32 certificateHash,
            uint256 certificateId,
            uint256 creationDt,
            string memory modelName,
            string memory manufacturer,
            string memory productionDate
        )
    {
        //require(batteries[_batteryId].isActive == true, "Battery does not exist.");
        require(isBatteryExist(_batteryId), "Battery does not exist.");

        Battery memory battery = batteries[_batteryId];

        return (
            battery.batteryId,
            //battery.owner,
            ownerOf(_batteryId),
            battery.certificateHash,
            battery.certificateId,
            battery.creationDt,
            battery.modelName,
            battery.manufacturer,
            battery.productionDate
        );
    }
    /*
    function getCertificateCount(uint256 _batteryId) public view returns(uint) {
        require(batteries[_batteryId].isActive == true, "Battery does not exist.");
        
        return certificateList[_batteryId].length;
    }
    */
    function getCertificateInfo(uint256 _batteryId, uint256 _certificateId)
        public
        view
        returns (
            uint256 batteryId, 
            uint256 certificateId, 
            string memory grade,
            string memory evaluationDate,
            string memory evaluationInstitute,
            bool isLatest
        )
    {
        //require(batteries[_batteryId].isActive == true, "Battery does not exist.");
        require(isBatteryExist(_batteryId), "Battery does not exist.");
        require(certificateList[_batteryId].length > 0, "Certificates do not exist.");
        //require(batteries[_batteryId].certificateId != 0, "Certificate is not set.");

        Certificate memory certificate = certificates[_batteryId][_certificateId];

        return (
            certificate.batteryId,
            certificate.certificateId,
            certificate.grade,
            certificate.evaluationDate,
            certificate.evaluationInstitute,
            certificate.isLatest
        );
    }
    
    function isBatteryOwner(uint256 _batteryId, address _ownerAddress) public view returns (bool) {
        //return (batteries[_batteryId].owner == _ownerAddress);
        return (ownerOf(_batteryId) == _ownerAddress);
    }
    
    function isBatteryExist(uint256 _batteryId) private view returns (bool) {
        return (batteries[_batteryId].isActive == true);
    }

}