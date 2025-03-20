// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract TokenizedGoalTracker {

    struct Goal {
        uint256 id;
        string description;
        uint256 targetAmount;
        uint256 currentAmount;
        bool isAchieved;
        address creator;
    }

    uint256 public goalCounter;
    mapping(uint256 => Goal) public goals;
    mapping(address => uint256[]) public userGoals;
    mapping(address => uint256) public tokenBalances;

    event GoalCreated(uint256 goalId, string description, uint256 targetAmount, address creator);
    event GoalProgressUpdated(uint256 goalId, uint256 newAmount, address updater);
    event GoalAchieved(uint256 goalId, address achiever);
    event TokensDeposited(address user, uint256 amount);
    event TokensWithdrawn(address user, uint256 amount);

    modifier onlyCreator(uint256 _goalId) {
        require(msg.sender == goals[_goalId].creator, "Only the creator can update the goal");
        _;
    }

    modifier goalExists(uint256 _goalId) {
        require(goals[_goalId].id != 0, "Goal does not exist");
        _;
    }

    modifier hasEnoughTokens(address _user, uint256 _amount) {
        require(tokenBalances[_user] >= _amount, "Insufficient tokens");
        _;
    }

    // Create a new goal
    function createGoal(string memory _description, uint256 _targetAmount) external {
        goalCounter++;
        uint256 goalId = goalCounter;

        goals[goalId] = Goal({
            id: goalId,
            description: _description,
            targetAmount: _targetAmount,
            currentAmount: 0,
            isAchieved: false,
            creator: msg.sender
        });

        userGoals[msg.sender].push(goalId);
        emit GoalCreated(goalId, _description, _targetAmount, msg.sender);
    }

    // Update progress on a goal
    function updateGoalProgress(uint256 _goalId, uint256 _amount) external onlyCreator(_goalId) goalExists(_goalId) {
        Goal storage goal = goals[_goalId];
        require(!goal.isAchieved, "Goal already achieved");

        goal.currentAmount += _amount;

        if (goal.currentAmount >= goal.targetAmount) {
            goal.isAchieved = true;
            emit GoalAchieved(_goalId, msg.sender);
        }

        emit GoalProgressUpdated(_goalId, goal.currentAmount, msg.sender);
    }

    // Deposit tokens to the user's balance
    function depositTokens() external payable {
        tokenBalances[msg.sender] += msg.value;
        emit TokensDeposited(msg.sender, msg.value);
    }

    // Withdraw tokens from the user's balance
    function withdrawTokens(uint256 _amount) external hasEnoughTokens(msg.sender, _amount) {
        tokenBalances[msg.sender] -= _amount;
        payable(msg.sender).transfer(_amount);
        emit TokensWithdrawn(msg.sender, _amount);
    }

    // Get details of a specific goal
    function getGoalDetails(uint256 _goalId) external view goalExists(_goalId) returns (Goal memory) {
        return goals[_goalId];
    }

    // Get all goals of a user
    function getUserGoals(address _user) external view returns (uint256[] memory) {
        return userGoals[_user];
    }

    // Get user's token balance
    function getUserBalance() external view returns (uint256) {
        return tokenBalances[msg.sender];
    }
}
