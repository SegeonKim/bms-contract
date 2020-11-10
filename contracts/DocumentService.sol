pragma solidity ^0.5.0;

import "@openzeppelin/upgrades/contracts/Initializable.sol";
import "@openzeppelin/contracts-ethereum-package/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts-ethereum-package/contracts/token/ERC721/ERC721Enumerable.sol";
import "@openzeppelin/contracts-ethereum-package/contracts/token/ERC721/ERC721Metadata.sol";
import "@openzeppelin/contracts-ethereum-package/contracts/token/ERC721/ERC721MetadataMintable.sol";

contract DocumentService is
    Initializable,
    ERC721,
    ERC721Enumerable,
    ERC721MetadataMintable
{
    address public owner;

    struct Document {
        uint256 documentId; 
        address owner; 
        string name; 
        bytes32 hash; 
        uint256 creationDate; 
        uint256 expirationDate; 
        mapping(address => uint256) accessor; 
        Log[] log;
        bool isActive;
    }

    struct Log {
        address actionAddress;
        LogType logType;
        uint256 creationDate;
    }

    enum LogType { Created, Accessed, Deleted }

    uint256 public documentCount;
    mapping(uint256 => Document) documents;
    
    modifier onlyDocumentOwner(uint256 _documentId) {
        require(isDocumentOwner(_documentId, msg.sender), "ERROR_DOCUMENT_NOT_OWNER");
        _;
    }

    modifier onlyAccessor(uint256 _documentId) {
        require(isAccessor(_documentId, msg.sender), "ERROR_ACCESS_DENIED");
        _;
    }
    
    event CreateDocument (
      address   indexed owner,
      uint256   documentId,
      string    name,
      bytes32   hash,
      uint256   expirationDate,
      string    documentURI
    );
    
    event DeleteDocument (
      address   indexed owner,
      uint256   documentId,
      LogType   logType
    );
    
    event AccessDocument (
      address   indexed owner,
      address   indexed accessor,
      uint256   documentId,
      bytes32   hash,
      uint256   accessCount
    );
    
    event GrantAccess(
      address   indexed owner,
      address   indexed accessor,
      uint256   documentId
    );
    
    event DenyAccess(
      address   indexed owner,
      address   indexed accessor,
      uint256   documentId
    );

    function initialize(
        string memory name,
        string memory symbol
    ) public initializer {
        owner = msg.sender;

        ERC721.initialize();
        ERC721Enumerable.initialize();
        ERC721Metadata.initialize(name, symbol);
        ERC721MetadataMintable.initialize(address(this));

        _removeMinter(address(this));
    }

    function createDocument (
        uint256 _documentId,
        string memory _name, 
        bytes32 _hash,
        address[] memory _accessor, 
        uint256 _expirationDate,
        string memory _documentURI 
    ) public {
        require(documents[_documentId].isActive == false, "ERROR_DOCUMENT_ID_EXISTS");
        require(bytes(_name).length > 0, "ERROR_INPUT_PARAMETERS");
        for (uint i = 0; i < _accessor.length; i++) {
            require(_accessor[i] != address(0), "ERROR_ZERO_ADDRESS");
        }
        
        documents[_documentId].documentId = _documentId;
        documents[_documentId].owner = msg.sender;
        documents[_documentId].name = _name;
        documents[_documentId].hash = _hash;
        documents[_documentId].creationDate = block.timestamp;
        documents[_documentId].expirationDate = _expirationDate;
        documents[_documentId].accessor[msg.sender] = 1;
        for (uint i = 0; i < _accessor.length; i++) {
            documents[_documentId].accessor[_accessor[i]] = 1;
        }
        documents[_documentId].isActive = true;
        appendLog(_documentId, LogType.Created);

        // ERC721 mapping
        _mint(msg.sender, _documentId);
        if(bytes(_name).length > 0) {
            _setTokenURI(_documentId, _documentURI);
        }

        documentCount ++;
        
        emit CreateDocument(msg.sender, _documentId, _name, _hash, _expirationDate, _documentURI);
    }

    function deleteDocument(uint256 _documentId) 
        public
        onlyDocumentOwner(_documentId)
    {
        require(documents[_documentId].isActive == true, "ERROR_DOCUMENT_NOT_EXISTS");
        require(getDocumentLastLog(_documentId) != LogType.Deleted, "ERROR_DOCUMENT_ALREADY_DELETED");

        _burn(_documentId);
        appendLog(_documentId, LogType.Deleted);
        
         emit DeleteDocument(msg.sender, _documentId, LogType.Deleted);
    }

    function accessDocument(uint256 _documentId)
        public
        onlyAccessor(_documentId)
    {
        require(documents[_documentId].isActive == true, "ERROR_DOCUMENT_NOT_EXISTS");
        require(getDocumentLastLog(_documentId) != LogType.Deleted, "ERROR_DOCUMENT_ALREADY_DELETED");
        require(documents[_documentId].expirationDate > block.timestamp, "ERROR_DOCUMET_EXPIRED");

        documents[_documentId].accessor[msg.sender] ++;
        appendLog(_documentId, LogType.Accessed);
        
        emit AccessDocument(documents[_documentId].owner, msg.sender, _documentId,  documents[_documentId].hash, (documents[_documentId].accessor[msg.sender] - 1));
    }

    function grantAccess(uint256 _documentId, address _accessAddress)
        public
        onlyDocumentOwner(_documentId)
    {
        require(documents[_documentId].isActive == true, "ERROR_DOCUMENT_NOT_EXISTS");
        require(getDocumentLastLog(_documentId) != LogType.Deleted, "ERROR_DOCUMENT_ALREADY_DELETED");
        require(!isAccessor(_documentId, _accessAddress), "ERROR_ADDRESS_EXISTS");
        
        documents[_documentId].accessor[_accessAddress] = 1;
        
        emit GrantAccess(documents[_documentId].owner, msg.sender, _documentId);
    }

    function denyAccess(uint256 _documentId, address _accessAddress)
        public
        onlyDocumentOwner(_documentId)
    {
        require(documents[_documentId].isActive == true, "ERROR_DOCUMENT_NOT_EXISTS");
        require(getDocumentLastLog(_documentId) != LogType.Deleted, "ERROR_DOCUMENT_ALREADY_DELETED");
        require(isAccessor(_documentId, _accessAddress), "ERROR_ADDRESS_NOT_EXISTS");
        
        delete documents[_documentId].accessor[_accessAddress];
        
        emit DenyAccess(documents[_documentId].owner, msg.sender, _documentId);
    }

    function getDocumentInfo(uint256 _documentId)
        public
        view
        returns (
            uint256, 
            address, 
            string memory, 
            bytes32,
            uint256, 
            uint256,
            uint256
        )
    {
        require(documents[_documentId].isActive == true, "ERROR_DOCUMENT_NOT_EXISTS");

        Document memory document = documents[_documentId];

        return (
            document.documentId,
            document.owner,
            document.name,
            document.hash,
            document.creationDate,
            document.expirationDate,
            document.log.length
        );
    }

    function getDocumentInfoByOwnerIndex (
        address _owner,
        uint256 _documentIndex
    )
        public
        view
        returns (
            uint256,
            address, 
            string memory, 
            bytes32,
            uint256, 
            uint256
        )
    {
        uint256 documentId = tokenOfOwnerByIndex(_owner, _documentIndex);
        require(documents[documentId].isActive == true, "ERROR_DOCUMENT_NOT_EXISTS");

        Document memory document = documents[documentId];

        return (
            document.documentId,
            document.owner,
            document.name,
            document.hash,
            document.creationDate,
            document.expirationDate
        );
    }
    
    function getDocumentLog(uint256 _documentId, uint256 _logIndex) public view returns (address, LogType, uint256) {
        require(documents[_documentId].isActive == true, "ERROR_DOCUMENT_NOT_EXISTS");
        require(documents[_documentId].log.length > _logIndex, "ERROR_LOG_INDEX_OUT_OF_RANGE");
        
        Log memory log = documents[_documentId].log[_logIndex];
        
        return (
            log.actionAddress,
            log.logType,
            log.creationDate
        );
    }
    
    function getDocumentLogCount(uint256 _documentId) public view returns (uint256) {
        require(documents[_documentId].isActive == true, "ERROR_DOCUMENT_NOT_EXISTS");
        return documents[_documentId].log.length;
    }
    
    function getDocumentAccessCount(uint256 _documentId, address _accessAddress) public view returns (uint256) {
        require(documents[_documentId].isActive == true, "ERROR_DOCUMENT_NOT_EXISTS");
        require(isAccessor(_documentId, _accessAddress) == true, "ERROR_ADDRESS_NOT_ACCESSOR");
        
        return (documents[_documentId].accessor[msg.sender] - 1);
    }

    function isDocumentOwner(uint256 _documentId, address _ownerAddress)
        public
        view
        returns (bool)
    {
        return (documents[_documentId].owner == _ownerAddress);
    }

    function isAccessor(uint256 _documentId, address _accessAddress)
        public
        view
        returns (bool)
    {
        return (documents[_documentId].accessor[_accessAddress] > 0);
    }

    function isExpiredDocument(uint256 _documentId) 
        public 
        view 
        returns(bool)
    {
        require(documents[_documentId].isActive == true, "ERROR_DOCUMENT_NOT_EXISTS");
        
        if(documents[_documentId].expirationDate < block.timestamp) {
            return true;
        } else {
            return false;
        }
    }
    
    function getDocumentLastLog(uint256 _documentId) private view returns (LogType) {
        return documents[_documentId].log[documents[_documentId].log.length - 1].logType;
    }

    function appendLog(uint256 _documentId, LogType logType) private {
        Log memory log = Log(msg.sender, logType, block.timestamp); 
        Document storage document = documents[_documentId];
        document.log.push(log);
    }
}