// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title IPool
 * @notice Aave V3 Pool 接口（简化版，仅包含 StakingPool 需要的方法）
 * @dev 基于 Aave V3 官方接口，包含 supply、withdraw、borrow、repay 等核心功能
 */
interface IPool {
    /**
     * @notice 供应资产到协议
     * @param asset 资产地址
     * @param amount 存款金额
     * @param onBehalfOf 代表谁存款
     * @param referralCode 推荐码（0 表示无推荐）
     */
    function supply(
        address asset,
        uint256 amount,
        address onBehalfOf,
        uint16 referralCode
    ) external;

    /**
     * @notice 从协议提取资产
     * @param asset 资产地址
     * @param amount 提取金额（type(uint256).max 表示提取全部）
     * @param to 接收地址
     * @return 最终提取金额
     */
    function withdraw(
        address asset,
        uint256 amount,
        address to
    ) external returns (uint256);

    /**
     * @notice 借款
     * @param asset 资产地址
     * @param amount 借款金额
     * @param interestRateMode 利率模式（0 = 无，1 = 稳定，2 = 可变）
     * @param referralCode 推荐码
     * @param onBehalfOf 代表谁借款
     */
    function borrow(
        address asset,
        uint256 amount,
        uint256 interestRateMode,
        uint16 referralCode,
        address onBehalfOf
    ) external;

    /**
     * @notice 还款
     * @param asset 资产地址
     * @param amount 还款金额（type(uint256).max 表示还清全部）
     * @param interestRateMode 利率模式
     * @param onBehalfOf 代表谁还款
     * @return 最终还款金额
     */
    function repay(
        address asset,
        uint256 amount,
        uint256 interestRateMode,
        address onBehalfOf
    ) external returns (uint256);
}
