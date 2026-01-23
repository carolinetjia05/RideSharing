// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract RideSharing {

   // Status pesanan
    enum RideStatus {
        Requested,          
        Accepted,           
        Funded,             
        Started,            
        CompletedByRider,   
        Finalized,          
        Cancelled            
    }

    // Data pengemudi
    struct Driver {
        string name;
        string plate;
        string vehicleType;
        uint256 tariff;
        bool registered;
    }

    // Data penumpang
    struct Ride {
        address rider;
        address driver;
        string pickup;
        string destination;
        uint256 price;
        RideStatus status;
    }

    /// Mapping alamat wallet pengemudi ke data pengemudi
    mapping(address => Driver) public drivers;

    /// Mapping ID ride ke data perjalanan
    mapping(uint256 => Ride) public rides;

    uint256 public rideCount;

    // Fungsi untuk mendaftarkan pengemudi
    function registerDriver(
        string memory name,
        string memory plate,
        string memory vehicleType,
        uint256 tariff
    ) public {
        drivers[msg.sender] = Driver(
            name,
            plate,
            vehicleType,
            tariff,
            true
        );
    }

    // Fungsi untuk membuat permintaan perjalanan oleh penumpang
    function requestRide(
        string memory pickup,
        string memory destination
    ) public {
        rideCount++;

        rides[rideCount] = Ride(
            msg.sender,
            address(0),
            pickup,
            destination,
            0,
            RideStatus.Requested
        );
    }

    // Fungsi untuk menerima pesanan oleh pengemudi
    function acceptRide(uint256 rideId) public {
        require(drivers[msg.sender].registered, "Not a driver");

        Ride storage r = rides[rideId];
        require(r.status == RideStatus.Requested, "Ride not available");

        r.driver = msg.sender;
        r.price = drivers[msg.sender].tariff;
        r.status = RideStatus.Accepted;
    }

    // Fungsi untuk membayar biaya perjalanan ke smart contract (escrow)
    function fundRide(uint256 rideId) public payable {
        Ride storage r = rides[rideId];

        require(msg.sender == r.rider, "Not rider");
        require(r.status == RideStatus.Accepted, "Ride not accepted");
        require(msg.value == r.price, "Incorrect ETH amount");

        r.status = RideStatus.Funded;
    }

    // Fungsi untuk memulai perjalanan oleh pengemudi
    function startRide(uint256 rideId) public {
        Ride storage r = rides[rideId];

        require(msg.sender == r.driver, "Not driver");
        require(r.status == RideStatus.Funded, "Ride not funded");

        r.status = RideStatus.Started;
    }

    // Fungsi untuk konfirmasi perjalanan selesai oleh penumpang
    function confirmArrival(uint256 rideId) public {
        Ride storage r = rides[rideId];

        require(msg.sender == r.rider, "Not rider");
        require(r.status == RideStatus.Started, "Ride not started");

        r.status = RideStatus.CompletedByRider;
    }

    // Fungsi untuk menyelesaikan perjalanan dan membayar pengemudi
    function completeRide(uint256 rideId) public {
        Ride storage r = rides[rideId];

        require(msg.sender == r.driver, "Not driver");
        require(r.status == RideStatus.CompletedByRider, "Rider not confirmed");

        r.status = RideStatus.Finalized;

    // Transfer ETH ke pengemudi 
        (bool success, ) = payable(r.driver).call{value: r.price}("");
        require(success, "ETH transfer failed");
    }


    // Fungsi untuk membatalkan perjalanan oleh penumpang
    function cancelRide(uint256 rideId) public {
        Ride storage r = rides[rideId];

        require(msg.sender == r.rider, "Not rider");
        require(
            r.status == RideStatus.Requested || r.status == RideStatus.Accepted,
            "Cannot cancel"
        );

        r.status = RideStatus.Cancelled;
    }

    // Fungsi untuk melihat data pengemudi berdasarkan alamat wallet
    function getDriver(address driver) public view returns (Driver memory) {
        return drivers[driver];
    }
}
