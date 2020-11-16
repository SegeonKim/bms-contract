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
        uint256 currentCertificateId; 
        string modelName;
        string manufacturer;
        string productionDate;
        uint256 creationDt; 
    }
    
    struct Certificate {
        uint256 batteryId;
        uint256 certificateId;
        bytes32 certificateHash;
		string  grade;
		string  evaluationDate;
		string  evaluationInstitute;
		bool    isLatest;
		uint256 creationDt;
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

    event CreateOwnership (
      address   indexed owner,
      uint256   batteryId,
      //string    batteryURI
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
        //string memory _batteryURI 
        address _owner,
        string memory _modelName,
        string memory _manufacturer,
        string memory _productionDate
    ) public onlyManager {
        require(!doesBatteryExist(_batteryId), "Battery ID exists.");
        
        batteries[_batteryId].batteryId = _batteryId;
        batteries[_batteryId].modelName = _modelName;
        batteries[_batteryId].manufacturer = _manufacturer;
        batteries[_batteryId].productionDate = _productionDate;
        batteries[_batteryId].creationDt = block.timestamp;

        // ERC-721 : mint
        _mint(_owner, _batteryId);
        //if (bytes(_batteryURI).length > 0) {
        //    _setTokenURI(_batteryId, _batteryURI);
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
        require(doesBatteryExist(_batteryId), "Battery does not exist.");
        
        batteries[_batteryId].currentCertificateId = _certificateId;
        
        certificates[_batteryId][_certificateId].batteryId = _batteryId;
        certificates[_batteryId][_certificateId].certificateId = _certificateId;
        certificates[_batteryId][_certificateId].certificateHash = _certificateHash;
	    certificates[_batteryId][_certificateId].grade = _grade;
        certificates[_batteryId][_certificateId].evaluationDate = _evaluationDate;
        certificates[_batteryId][_certificateId].evaluationInstitute = _evaluationInstitute;
		certificates[_batteryId][_certificateId].grade = _grade;
        certificates[_batteryId][_certificateId].isLatest = true;
        certificates[_batteryId][_certificateId].creationDt = block.timestamp;
        
		for (uint i = 0;i < certificateList[_batteryId].length;i++) {
            if (certificates[_batteryId][certificateList[_batteryId][i]].isLatest == true)
                certificates[_batteryId][certificateList[_batteryId][i]].isLatest = false;
        }
        certificateList[_batteryId].push(_certificateId);
        
        emit SaveCertificateHash(_batteryId, _certificateHash, _certificateId, _grade, _evaluationDate, _evaluationInstitute);
    }
    
    function validateCertificateHash(uint256 _batteryId, bytes32 _certificateHash) public view returns(bool)  {
        require(doesBatteryExist(_batteryId), "Battery does not exist.");
        require(certificates[_batteryId][batteries[_batteryId].currentCertificateId].creationDt != 0, "Certificate does not exist.");

        return (certificates[_batteryId][batteries[_batteryId].currentCertificateId].certificateHash == _certificateHash);
    }

    function deleteOwnership(uint256 _batteryId) public onlyBatteryOwner(_batteryId) {
        require(doesBatteryExist(_batteryId), "Battery does not exist.");
        
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
            bytes32 currentCertificateHash,
            uint256 currentCertificateId,
            uint256 creationDt,
            string memory modelName,
            string memory manufacturer,
            string memory productionDate
        )
    {
        require(doesBatteryExist(_batteryId), "Battery does not exist.");

        Battery memory battery = batteries[_batteryId];

        return (
            battery.batteryId,
            ownerOf(_batteryId),
            certificates[_batteryId][battery.currentCertificateId].certificateHash,
            battery.currentCertificateId,
            battery.creationDt,
            battery.modelName,
            battery.manufacturer,
            battery.productionDate
        );
    }

    function getCertificateInfo(uint256 _batteryId, uint256 _certificateId)
        public
        view
        returns (
            uint256 batteryId, 
            uint256 certificateId,
            bytes32 certificateHash,
            string memory grade,
            string memory evaluationDate,
            string memory evaluationInstitute,
            bool isLatest
        )
    {
        require(doesBatteryExist(_batteryId), "Battery does not exist.");
        require(certificates[_batteryId][_certificateId].creationDt != 0, "Certificate does not exist.");

        Certificate memory certificate = certificates[_batteryId][_certificateId];

        return (
            certificate.batteryId,
            certificate.certificateId,
            certificate.certificateHash,
            certificate.grade,
            certificate.evaluationDate,
            certificate.evaluationInstitute,
            certificate.isLatest
        );
    }
    
    function isBatteryOwner(uint256 _batteryId, address _ownerAddress) public view returns (bool) {
        return (ownerOf(_batteryId) == _ownerAddress);
    }
    
    function doesBatteryExist(uint256 _batteryId) private view returns (bool) {
        return (batteries[_batteryId].creationDt != 0);
    }

}