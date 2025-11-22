import { SuiClient } from '@mysten/sui/client';
import {useNetworkVariable, useNetworkVariables, networkConfig} from '../networkConfig'

const FULLNODE_URL = process.env.REACT_APP_FULLNODE_URL as string;
export const PACKAGE_ID = process.env.REACT_APP_PACKAGE_ID as string;

export const SUI_CLIENT = new SuiClient({ url: networkConfig['devnet'].url});