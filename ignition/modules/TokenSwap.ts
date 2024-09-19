import { buildModule } from "@nomicfoundation/hardhat-ignition/modules";

const TokenSwapModule = buildModule("TokenSwapModule", (m) => {
  const tokenSwap = m.contract("TokenSwap");

  return { tokenSwap };
});

export default TokenSwapModule;
