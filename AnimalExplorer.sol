// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

//TODO validation only owner can add area
contract AnimalExplorer is ERC20, Ownable {

    constructor(address initialOwner) ERC20("AnimalExplorer", "RAE") Ownable(initialOwner) {
    }

    event Log(string message);

    //utils
    uint randomNonce = 0;
    uint searchNonce = 0;

    //area
    struct Coordinate {
        int32 x;
        int32 y;
    }

    struct Area {
        uint areaId;
        Coordinate [] coordinates;
    }

    Area [] public areas;

    //animal
    struct Animal {
        uint animalId;
        Area [] occuranceAreas;
    }

    Animal [] animals;

    //other
    uint [] animalsInArea;
    uint animalCatchedStatus;

    //user
    struct CatchedAnimal {
        uint animalId;
    }

    struct User {
        uint userId;
        address userAddress;
        CatchedAnimal [] userAnimals;
    }

    User [] users;

    //utils
    function intToString(int number) public pure returns (string memory) {
        string memory sign = "";
        if (number < 0) {
            sign = "-";
        }

        return string.concat(sign, Strings.toString(uint(number)));
    }

    function random(uint minNumber, uint maxNumber) public returns (uint randomNumber) {
        randomNonce++;

        randomNumber = uint(keccak256(abi.encodePacked(block.timestamp, msg.sender, randomNonce))) % (maxNumber - minNumber);
        randomNumber = randomNumber + minNumber;

        emit Log(string.concat("Random number from ", Strings.toString(minNumber), " - ", Strings.toString(maxNumber), " drown number is ", Strings.toString(randomNumber)));
        
        return randomNumber;
    }

    //area
    function createArea(Coordinate [] memory _coordinates) public onlyOwner {
        Area storage area = areas.push();

        area.areaId = areas.length;
        for (uint i = 0; i < _coordinates.length; i++) {
            Coordinate storage coordinate = area.coordinates.push();

            //TODO validation only two coordinate parameters 
            coordinate.x = _coordinates[i].x;
            coordinate.y = _coordinates[i].y;

            emit Log(string.concat("Coordinate (", Strings.toString(i) ,") - x: ", this.intToString(_coordinates[i].x), ", y: ", this.intToString(_coordinates[i].y)));
        }
    }

    //TODO change to internal after development
    function getAreaAll() external view returns (Area [] memory) {
        return areas;
    }

    //TODO change to internal after development
    function getAreaById(uint areaId) external view returns (Area memory) {
        return areas[areaId];
    }

    //TODO change to internal after development
    function drawArea() public returns (Area memory) {
        uint areaId = random(0, areas.length);

        return areas[areaId];
    }

    //animal
    function createAnimal() public onlyOwner {
        Animal storage animal = animals.push();

        animal.animalId = animals.length;

        //TODO validation block if there are not any areas
        Area memory drawnArea = this.drawArea();

        //TODO move to animal function
        Area storage area = animal.occuranceAreas.push();

        area.areaId = areas.length;
        for (uint i = 0; i < drawnArea.coordinates.length; i++) {
            Coordinate storage coordinate = area.coordinates.push();

            //TODO validation only two coordinate parameters 
            coordinate.x = drawnArea.coordinates[i].x;
            coordinate.y = drawnArea.coordinates[i].y;
        }
    }

    //TODO change to internal after development
    function getAnimalAll() external view returns (Animal [] memory) {
        return animals;
    }

    //TODO change to internal after development
    function getAnimalById(uint animalId) external view returns (Animal memory) {
        return animals[animalId];
    }

    //TODO change to internal after development
    function drawAnimal() public returns (Animal memory) {
        uint animalId = random(0, animals.length);

        return animals[animalId];
    }

    //other
    function min(int32 n1, int32 n2) public pure returns (int32) {
        if (n1 <= n2) {
            return n1;
        }

        return n2;
    }

    function max(int32 n1, int32 n2) public pure returns (int32) {
        if (n1 >= n2) {
            return n1;
        }

        return n2;
    }

    function inPolygon(int32 x, int32 y, Coordinate [] memory polygon) public pure returns (bool) {
        bool isInside = false;

        uint verticeNumber = polygon.length;
        
        Coordinate memory p1 = polygon[0];
        Coordinate memory p2 = Coordinate(0, 0);

        for (uint i = 1; i <= verticeNumber; i++) {
            p2 = polygon[i % verticeNumber];

            if (y > min(p1.y, p2.y)) {
                if (y <= max(p1.y, p2.y)) {
                    if (x <= max(p1.x, p2.x)) {
                        int32 xIntersection = (y - p1.y) * (p2.x - p1.x) / (p2.y - p1.y) + p1.x;

                        if (p1.x == p2.x || x <= xIntersection) {
                        isInside = !isInside;
                        }
                    }
                }
            }

            p1 = p2;
        }

        return isInside;
    }

    function searchAnimal(int32 x, int32 y) public returns (bool) {
        searchNonce++;

        delete animalsInArea;
 
        bool animalAtPoint = false;
        for (uint i = 0; i < animals.length; i++) {
            for (uint j = 0; j < animals[i].occuranceAreas.length; j++) {
                animalAtPoint = this.inPolygon(x, y, animals[i].occuranceAreas[j].coordinates);
                if (animalAtPoint) {
                    animalsInArea.push(i);
                }
            }
        }

        if (animalsInArea.length > 0) {
            return true;
        }
        
        return false;
    }

    function getAnimalsInArea() public view returns (uint [] memory) {
        return animalsInArea;
    }

    function drawFight() public returns (bool) {
        uint fightId = random(0, 100);

        return fightId % 2 == 0 ? true : false;
    }

    function isAnimalInArea(uint animalId) public view returns (bool) {
        for (uint i = 0; i < animalsInArea.length; i++) {
            if (animalsInArea[i] == animalId) {
                return true;
            }
        }

        return false;
    }

    function catchAnimal(int32 x, int32 y, uint animalId) public returns (bool) {
        animalCatchedStatus = 0;

        bool isAnimalIsInArea = searchAnimal(x, y);
        if (!isAnimalIsInArea) {
            animalCatchedStatus = 1;

            return false;
        }

        animalCatchedStatus = 21;

        bool isAnimalHere = this.isAnimalInArea(animalId);
        if (!isAnimalHere) {
            animalCatchedStatus = 2;

            return false;
        }
        
        animalCatchedStatus = 22;

        bool isAnimalCatched = drawFight();
        if (!isAnimalCatched) {
            animalCatchedStatus = 3;

            return false;
        }

        animalCatchedStatus = 23;

        address userAddress = msg.sender;

        int userArryIndex = -1;
        for (uint i = 0; i < users.length; i++) {
            if (users[i].userAddress == userAddress) {
                userArryIndex = int(i);
            }
        }
        
        animalCatchedStatus = 24;

        if (userArryIndex == -1) {
            animalCatchedStatus = 10;

            User storage user = users.push();
            user.userId = users.length;
            user.userAddress = userAddress;
            
            CatchedAnimal storage catchedAnimal = user.userAnimals.push();
            catchedAnimal.animalId = animalId;
        } else {
            animalCatchedStatus = 11;

            User storage user = users[uint(userArryIndex)];

            CatchedAnimal storage catchedAnimal = user.userAnimals.push();
            catchedAnimal.animalId = animalId;
        }

        return isAnimalCatched;
    }

    //TODO change to internal after development
    function getUserAll() external view returns (User [] memory) {
        return users;
    }

    //TODO change to internal after development
    function getUserById(uint userId) external view returns (User memory) {
        return users[userId];
    }

    //TODO change to internal after development
    function getAnimalCatchedStatus() external view returns (uint) {
        return animalCatchedStatus;
    }
}

/*
area

[ [10,10], [10,-10], [-10,-10], [-10,10] ]
[ [15,15], [15,25], [25,25], [25,15] ]
[ [30,-20], [30,-10], [40,-10], [40,-20] ]
[ [60,10], [60,20], [70,20], [70,10] ]
[ [-30,-30], [-30,-20], [-20,-20], [-20,-30] ]
[ [-30,30], [-30,40], [-20,40], [-20,30] ]

1. add 3 (5) new areas
2. create 2 (3) animals
3. get all animals
4. search animal - two animals but should be one
5. get animals in area
6. catch animal by id - sometimes it wasn't work :/
7. get is animal catched
8. get user animals

hide unused functions
//*/