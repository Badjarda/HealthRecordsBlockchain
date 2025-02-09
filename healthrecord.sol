// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

contract HealthRecord {
    struct Record {
        string ipfsHash;
        address doctor;
        uint256 timestamp;
    }

    struct Patient {
        bool registered;
        address[] authorizedDoctors;
        Record[] records;
    }

    mapping(address => Patient) private patients;

    event RecordAdded(address indexed patient, string ipfsHash, address indexed doctor);
    event AccessGranted(address indexed patient, address indexed doctor);
    event AccessRevoked(address indexed patient, address indexed doctor);

    modifier onlyPatient() {
        require(patients[msg.sender].registered, "Not registered as a patient");
        _;
    }

    modifier onlyAuthorized(address _patient) {
        require(patients[_patient].registered, "Patient not found");
        bool authorized = false;
        for (uint256 i = 0; i < patients[_patient].authorizedDoctors.length; i++) {
            if (patients[_patient].authorizedDoctors[i] == msg.sender) {
                authorized = true;
                break;
            }
        }
        require(authorized, "Not authorized");
        _;
    }

    function registerPatient() external {
        require(!patients[msg.sender].registered, "Already registered");
        patients[msg.sender].registered = true;
    }

    function grantAccess(address _doctor) external onlyPatient {
        patients[msg.sender].authorizedDoctors.push(_doctor);
        emit AccessGranted(msg.sender, _doctor);
    }

    function revokeAccess(address _doctor) external onlyPatient {
        for (uint256 i = 0; i < patients[msg.sender].authorizedDoctors.length; i++) {
            if (patients[msg.sender].authorizedDoctors[i] == _doctor) {
                patients[msg.sender].authorizedDoctors[i] = patients[msg.sender].authorizedDoctors[
                    patients[msg.sender].authorizedDoctors.length - 1
                ];
                patients[msg.sender].authorizedDoctors.pop();
                emit AccessRevoked(msg.sender, _doctor);
                return;
            }
        }
    }

    function addRecord(address _patient, string memory _ipfsHash) external onlyAuthorized(_patient) {
        patients[_patient].records.push(Record(_ipfsHash, msg.sender, block.timestamp));
        emit RecordAdded(_patient, _ipfsHash, msg.sender);
    }

    function getRecords() external view onlyPatient returns (Record[] memory) {
        return patients[msg.sender].records;
    }
}
