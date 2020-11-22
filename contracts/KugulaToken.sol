// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

import "./../node_modules/@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "./../node_modules/@openzeppelin/contracts/access/Ownable.sol";


// this library from https://github.com/bokkypoobah/BokkyPooBahsDateTimeLibrary/blob/master/contracts/BokkyPooBahsDateTimeLibrary.sol
library BokkyPooBahsDateTimeLibrary {

    uint constant SECONDS_PER_DAY = 24 * 60 * 60;
    uint constant SECONDS_PER_HOUR = 60 * 60;
    uint constant SECONDS_PER_MINUTE = 60;
    int constant OFFSET19700101 = 2440588;

    uint constant DOW_MON = 1;
    uint constant DOW_TUE = 2;
    uint constant DOW_WED = 3;
    uint constant DOW_THU = 4;
    uint constant DOW_FRI = 5;
    uint constant DOW_SAT = 6;
    uint constant DOW_SUN = 7;

    // ------------------------------------------------------------------------
    // Calculate the number of days from 1970/01/01 to year/month/day using
    // the date conversion algorithm from
    //   http://aa.usno.navy.mil/faq/docs/JD_Formula.php
    // and subtracting the offset 2440588 so that 1970/01/01 is day 0
    //
    // days = day
    //      - 32075
    //      + 1461 * (year + 4800 + (month - 14) / 12) / 4
    //      + 367 * (month - 2 - (month - 14) / 12 * 12) / 12
    //      - 3 * ((year + 4900 + (month - 14) / 12) / 100) / 4
    //      - offset
    // ------------------------------------------------------------------------
    function _daysFromDate(uint year, uint month, uint day) internal pure returns (uint _days) {
        require(year >= 1970);
        int _year = int(year);
        int _month = int(month);
        int _day = int(day);

        int __days = _day
          - 32075
          + 1461 * (_year + 4800 + (_month - 14) / 12) / 4
          + 367 * (_month - 2 - (_month - 14) / 12 * 12) / 12
          - 3 * ((_year + 4900 + (_month - 14) / 12) / 100) / 4
          - OFFSET19700101;

        _days = uint(__days);
    }

    // ------------------------------------------------------------------------
    // Calculate year/month/day from the number of days since 1970/01/01 using
    // the date conversion algorithm from
    //   http://aa.usno.navy.mil/faq/docs/JD_Formula.php
    // and adding the offset 2440588 so that 1970/01/01 is day 0
    //
    // int L = days + 68569 + offset
    // int N = 4 * L / 146097
    // L = L - (146097 * N + 3) / 4
    // year = 4000 * (L + 1) / 1461001
    // L = L - 1461 * year / 4 + 31
    // month = 80 * L / 2447
    // dd = L - 2447 * month / 80
    // L = month / 11
    // month = month + 2 - 12 * L
    // year = 100 * (N - 49) + year + L
    // ------------------------------------------------------------------------
    function _daysToDate(uint _days) internal pure returns (uint year, uint month, uint day) {
        int __days = int(_days);

        int L = __days + 68569 + OFFSET19700101;
        int N = 4 * L / 146097;
        L = L - (146097 * N + 3) / 4;
        int _year = 4000 * (L + 1) / 1461001;
        L = L - 1461 * _year / 4 + 31;
        int _month = 80 * L / 2447;
        int _day = L - 2447 * _month / 80;
        L = _month / 11;
        _month = _month + 2 - 12 * L;
        _year = 100 * (N - 49) + _year + L;

        year = uint(_year);
        month = uint(_month);
        day = uint(_day);
    }

    function timestampFromDate(uint year, uint month, uint day) internal pure returns (uint timestamp) {
        timestamp = _daysFromDate(year, month, day) * SECONDS_PER_DAY;
    }
    function timestampFromDateTime(uint year, uint month, uint day, uint hour, uint minute, uint second) internal pure returns (uint timestamp) {
        timestamp = _daysFromDate(year, month, day) * SECONDS_PER_DAY + hour * SECONDS_PER_HOUR + minute * SECONDS_PER_MINUTE + second;
    }
    function timestampToDate(uint timestamp) internal pure returns (uint year, uint month, uint day) {
        (year, month, day) = _daysToDate(timestamp / SECONDS_PER_DAY);
    }
    function timestampToDateTime(uint timestamp) internal pure returns (uint year, uint month, uint day, uint hour, uint minute, uint second) {
        (year, month, day) = _daysToDate(timestamp / SECONDS_PER_DAY);
        uint secs = timestamp % SECONDS_PER_DAY;
        hour = secs / SECONDS_PER_HOUR;
        secs = secs % SECONDS_PER_HOUR;
        minute = secs / SECONDS_PER_MINUTE;
        second = secs % SECONDS_PER_MINUTE;
    }

    function isValidDate(uint year, uint month, uint day) internal pure returns (bool valid) {
        if (year >= 1970 && month > 0 && month <= 12) {
            uint daysInMonth = _getDaysInMonth(year, month);
            if (day > 0 && day <= daysInMonth) {
                valid = true;
            }
        }
    }
    function isValidDateTime(uint year, uint month, uint day, uint hour, uint minute, uint second) internal pure returns (bool valid) {
        if (isValidDate(year, month, day)) {
            if (hour < 24 && minute < 60 && second < 60) {
                valid = true;
            }
        }
    }
    function isLeapYear(uint timestamp) internal pure returns (bool leapYear) {
        (uint year,,) = _daysToDate(timestamp / SECONDS_PER_DAY);
        leapYear = _isLeapYear(year);
    }
    function _isLeapYear(uint year) internal pure returns (bool leapYear) {
        leapYear = ((year % 4 == 0) && (year % 100 != 0)) || (year % 400 == 0);
    }
    function isWeekDay(uint timestamp) internal pure returns (bool weekDay) {
        weekDay = getDayOfWeek(timestamp) <= DOW_FRI;
    }
    function isWeekEnd(uint timestamp) internal pure returns (bool weekEnd) {
        weekEnd = getDayOfWeek(timestamp) >= DOW_SAT;
    }
    function getDaysInMonth(uint timestamp) internal pure returns (uint daysInMonth) {
        (uint year, uint month,) = _daysToDate(timestamp / SECONDS_PER_DAY);
        daysInMonth = _getDaysInMonth(year, month);
    }
    function _getDaysInMonth(uint year, uint month) internal pure returns (uint daysInMonth) {
        if (month == 1 || month == 3 || month == 5 || month == 7 || month == 8 || month == 10 || month == 12) {
            daysInMonth = 31;
        } else if (month != 2) {
            daysInMonth = 30;
        } else {
            daysInMonth = _isLeapYear(year) ? 29 : 28;
        }
    }
    // 1 = Monday, 7 = Sunday
    function getDayOfWeek(uint timestamp) internal pure returns (uint dayOfWeek) {
        uint _days = timestamp / SECONDS_PER_DAY;
        dayOfWeek = (_days + 3) % 7 + 1;
    }

    function getYear(uint timestamp) internal pure returns (uint year) {
        (year,,) = _daysToDate(timestamp / SECONDS_PER_DAY);
    }
    function getMonth(uint timestamp) internal pure returns (uint month) {
        (,month,) = _daysToDate(timestamp / SECONDS_PER_DAY);
    }
    function getDay(uint timestamp) internal pure returns (uint day) {
        (,,day) = _daysToDate(timestamp / SECONDS_PER_DAY);
    }
    function getHour(uint timestamp) internal pure returns (uint hour) {
        uint secs = timestamp % SECONDS_PER_DAY;
        hour = secs / SECONDS_PER_HOUR;
    }
    function getMinute(uint timestamp) internal pure returns (uint minute) {
        uint secs = timestamp % SECONDS_PER_HOUR;
        minute = secs / SECONDS_PER_MINUTE;
    }
    function getSecond(uint timestamp) internal pure returns (uint second) {
        second = timestamp % SECONDS_PER_MINUTE;
    }

    function addYears(uint timestamp, uint _years) internal pure returns (uint newTimestamp) {
        (uint year, uint month, uint day) = _daysToDate(timestamp / SECONDS_PER_DAY);
        year += _years;
        uint daysInMonth = _getDaysInMonth(year, month);
        if (day > daysInMonth) {
            day = daysInMonth;
        }
        newTimestamp = _daysFromDate(year, month, day) * SECONDS_PER_DAY + timestamp % SECONDS_PER_DAY;
        require(newTimestamp >= timestamp);
    }
    function addMonths(uint timestamp, uint _months) internal pure returns (uint newTimestamp) {
        (uint year, uint month, uint day) = _daysToDate(timestamp / SECONDS_PER_DAY);
        month += _months;
        year += (month - 1) / 12;
        month = (month - 1) % 12 + 1;
        uint daysInMonth = _getDaysInMonth(year, month);
        if (day > daysInMonth) {
            day = daysInMonth;
        }
        newTimestamp = _daysFromDate(year, month, day) * SECONDS_PER_DAY + timestamp % SECONDS_PER_DAY;
        require(newTimestamp >= timestamp);
    }
    function addDays(uint timestamp, uint _days) internal pure returns (uint newTimestamp) {
        newTimestamp = timestamp + _days * SECONDS_PER_DAY;
        require(newTimestamp >= timestamp);
    }
    function addHours(uint timestamp, uint _hours) internal pure returns (uint newTimestamp) {
        newTimestamp = timestamp + _hours * SECONDS_PER_HOUR;
        require(newTimestamp >= timestamp);
    }
    function addMinutes(uint timestamp, uint _minutes) internal pure returns (uint newTimestamp) {
        newTimestamp = timestamp + _minutes * SECONDS_PER_MINUTE;
        require(newTimestamp >= timestamp);
    }
    function addSeconds(uint timestamp, uint _seconds) internal pure returns (uint newTimestamp) {
        newTimestamp = timestamp + _seconds;
        require(newTimestamp >= timestamp);
    }

    function subYears(uint timestamp, uint _years) internal pure returns (uint newTimestamp) {
        (uint year, uint month, uint day) = _daysToDate(timestamp / SECONDS_PER_DAY);
        year -= _years;
        uint daysInMonth = _getDaysInMonth(year, month);
        if (day > daysInMonth) {
            day = daysInMonth;
        }
        newTimestamp = _daysFromDate(year, month, day) * SECONDS_PER_DAY + timestamp % SECONDS_PER_DAY;
        require(newTimestamp <= timestamp);
    }
    function subMonths(uint timestamp, uint _months) internal pure returns (uint newTimestamp) {
        (uint year, uint month, uint day) = _daysToDate(timestamp / SECONDS_PER_DAY);
        uint yearMonth = year * 12 + (month - 1) - _months;
        year = yearMonth / 12;
        month = yearMonth % 12 + 1;
        uint daysInMonth = _getDaysInMonth(year, month);
        if (day > daysInMonth) {
            day = daysInMonth;
        }
        newTimestamp = _daysFromDate(year, month, day) * SECONDS_PER_DAY + timestamp % SECONDS_PER_DAY;
        require(newTimestamp <= timestamp);
    }
    function subDays(uint timestamp, uint _days) internal pure returns (uint newTimestamp) {
        newTimestamp = timestamp - _days * SECONDS_PER_DAY;
        require(newTimestamp <= timestamp);
    }
    function subHours(uint timestamp, uint _hours) internal pure returns (uint newTimestamp) {
        newTimestamp = timestamp - _hours * SECONDS_PER_HOUR;
        require(newTimestamp <= timestamp);
    }
    function subMinutes(uint timestamp, uint _minutes) internal pure returns (uint newTimestamp) {
        newTimestamp = timestamp - _minutes * SECONDS_PER_MINUTE;
        require(newTimestamp <= timestamp);
    }
    function subSeconds(uint timestamp, uint _seconds) internal pure returns (uint newTimestamp) {
        newTimestamp = timestamp - _seconds;
        require(newTimestamp <= timestamp);
    }

    function diffYears(uint fromTimestamp, uint toTimestamp) internal pure returns (uint _years) {
        require(fromTimestamp <= toTimestamp);
        (uint fromYear,,) = _daysToDate(fromTimestamp / SECONDS_PER_DAY);
        (uint toYear,,) = _daysToDate(toTimestamp / SECONDS_PER_DAY);
        _years = toYear - fromYear;
    }
    function diffMonths(uint fromTimestamp, uint toTimestamp) internal pure returns (uint _months) {
        require(fromTimestamp <= toTimestamp);
        (uint fromYear, uint fromMonth,) = _daysToDate(fromTimestamp / SECONDS_PER_DAY);
        (uint toYear, uint toMonth,) = _daysToDate(toTimestamp / SECONDS_PER_DAY);
        _months = toYear * 12 + toMonth - fromYear * 12 - fromMonth;
    }
    function diffDays(uint fromTimestamp, uint toTimestamp) internal pure returns (uint _days) {
        require(fromTimestamp <= toTimestamp);
        _days = (toTimestamp - fromTimestamp) / SECONDS_PER_DAY;
    }
    function diffHours(uint fromTimestamp, uint toTimestamp) internal pure returns (uint _hours) {
        require(fromTimestamp <= toTimestamp);
        _hours = (toTimestamp - fromTimestamp) / SECONDS_PER_HOUR;
    }
    function diffMinutes(uint fromTimestamp, uint toTimestamp) internal pure returns (uint _minutes) {
        require(fromTimestamp <= toTimestamp);
        _minutes = (toTimestamp - fromTimestamp) / SECONDS_PER_MINUTE;
    }
    function diffSeconds(uint fromTimestamp, uint toTimestamp) internal pure returns (uint _seconds) {
        require(fromTimestamp <= toTimestamp);
        _seconds = toTimestamp - fromTimestamp;
    }
}


contract KugulaToken is ERC20 ,Ownable {
    
    mapping(address => uint) public Staked; // total Staked for sender
    mapping(address => uint) public DailyEarning; 
    mapping(address => bool) public HasStake;
    mapping(address => uint) public StartDate;
    mapping(address => uint) public LastWithdrawDate;
    mapping(address => uint) public Withdrawed;
    mapping(address => uint) public Earned;
    mapping(address => uint) public EarningPercent;
    uint public DailyEarningPercent  = 100;

    constructor() public ERC20("Kugula Token","KGL") {
        _mint(msg.sender, 10000000000000000000000000);
    }

    function createStake(uint _amount) public 
    {
        /* 
            * check stake availability
        */
        address sender = msg.sender;
        uint256 balanceSender = balanceOf(sender);
        //amount must be highr from 10
        require(_amount > 10, "Stake Amount must be highr from 50 KGL!");
        // amount cannot be higher from your balance
        require(_amount <=  balanceSender, "Stake amount can't be higher from your balance!");
        // sender must be don't have active 
        require(!HasStake[sender], "Your wallet address have a active Stake!");
        
        // set has lock
        HasStake[sender]          =  true;
        // set Earning Percent
        EarningPercent[sender]    =  DailyEarningPercent;
        // set Stake amount
        Staked[sender]            =  _amount;
        // set Daily earning
        uint dailyEarning         =  dailyEarningCalculate(_amount,sender);
        DailyEarning[sender]      =  dailyEarning;
         // set date locking
        StartDate[sender]         =  now;
        // set total earined
        uint earined              =  dailyEarning * 360;
        Earned[sender]            =  earined;
        // set Withdrawed to zero
        Withdrawed[sender]        =  0;
        // burn amount from balance of sender
        _burn(sender, _amount);
    }
    
    function stakeStatus() public view returns(
        bool HasStakeStatus,
        uint StakedTotal,
        uint DailyEarningAmount,
        uint StartDateValue,
        uint LastWithdrawDateValue,
        uint WithdrawedTotal,
        uint earinedTotal,
        uint EarningPercentAmount
        ) {
         address sender = msg.sender;
         // check sender have a stake
         require(HasStake[sender], "Your wallet address don't have active Stake!");
         
         HasStakeStatus              = HasStake[sender];
         StakedTotal                 = Staked[sender];
         DailyEarningAmount          = DailyEarning[sender];
         StartDateValue              = StartDate[sender];
         WithdrawedTotal             = Withdrawed[sender];
         LastWithdrawDateValue       = LastWithdrawDate[sender];
         earinedTotal                = Earned[sender];
         EarningPercentAmount        = EarningPercent[sender];
    }
    
    function dailyEarningCalculate(uint256 _amount,address sender) public view returns(uint) {
        // daily earning 
        return _amount * EarningPercent[sender] / 10000;
    }
    
    function withdrawDailyEarning() public {
         address sender = msg.sender;
         require(HasStake[sender], "Your wallet address don't have active Stake!");
         
         if (LastWithdrawDate[sender] != 0) {
             // diff days From Start Date To Last Withdraw Date
             uint dw  = BokkyPooBahsDateTimeLibrary.diffDays(StartDate[sender],LastWithdrawDate[sender]);
             // if dw highr from 365 day cann't get earning
             require(dw < 365, " Your Stake duration has finished!");
         }
            
         // date now
         uint dateNow = now;

         // date last withdraw 
         uint date = LastWithdrawDate[sender];
         if (LastWithdrawDate[sender] == 0) {  date = StartDate[sender]; }
         
         // get diffrent days
         uint diffDays     = BokkyPooBahsDateTimeLibrary.diffDays(date,dateNow);
         
         // check if diffrent days > 0
         require(diffDays > 0, "You can send withdraw request tomorrow"); 
         
         // withdraw amount 
         uint256 WithdrawAmount = diffDays * DailyEarning[sender];
         
         // send daily earnings to sender 
         _mint(sender, WithdrawAmount);
         
         // set last withdraw date 
         LastWithdrawDate[sender]  = BokkyPooBahsDateTimeLibrary.addDays(date,diffDays);
         
         // set withdrawed total 
         Withdrawed[sender]  = Withdrawed[sender] + WithdrawAmount ;
    }
    
    function unlockStakeLock() public {
         address sender = msg.sender;
         // sender must have a active Stake
         require(HasStake[sender], "Your wallet address don't have active Stake!");
         
         // sender must have Withdrawed amount 
         require(LastWithdrawDate[sender] == 0, "You must send withdraw request before call unlock function");
         
         // diff Months From Start Date To Last Withdraw Date
         uint deff  = BokkyPooBahsDateTimeLibrary.diffDays(StartDate[sender],now);
         
         // if rerequest before 1 year from start lock
         require(deff > 365, "Your Stake duration has not completed 1 year!");
         
         // earnings amount must be Withdrawed
         require(Withdrawed[sender] == Earned[sender], "You must send withdraw request before call unlock function");
         
         // send 
         _mint(sender, Staked[sender]);
         
         // reset Stake Data For sender
         
         // set has lock
         HasStake[sender]          =  false;
         // set locked amount
         Staked[sender]            =  0;
         // set monthly earning
         DailyEarning[sender]      =  0;
         // set date locking
         StartDate[sender]         =  0;
         // set total earined
         Earned[sender]            =  0;
         // set Withdrawed to zero
         Withdrawed[sender]        =  0;
         // set Earning Percent
         EarningPercent[sender]    =  0;
    }
    
    function updateDailyEarningPercent (uint _percent) public onlyOwner {
        DailyEarningPercent = _percent;
    } 
    
    function transferRewards(uint _amount,address recipient)  public onlyOwner {
        _mint(recipient, _amount);
    }
    
}
