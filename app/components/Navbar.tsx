"use client";

import * as React from "react";
import Link from "next/link";
import { ConnectButton } from "@mysten/dapp-kit";
import {
  NavigationMenu,
  NavigationMenuItem,
  NavigationMenuLink,
  NavigationMenuList,
} from "./ui/navigation-menu";
import { useView } from "../contexts/ViewContext";
import { useZkLogin } from "../contexts/ZkLoginContext";
import { Button } from "./ui/button";
import { User } from "lucide-react";

export default function Navbar() {
  const { setView } = useView();
  const { isAuthenticated, walletAddress, login, logout, isLoading } = useZkLogin();

  return (
    <NavigationMenu className="max-w-full p-4 border-b">
      <NavigationMenuList className="flex w-full items-center justify-between">
        {/* Left: Logo */}
        <NavigationMenuItem>
          <NavigationMenuLink asChild>
            <Link
              href="/"
              className="flex items-center space-x-2 font-semibold text-lg"
              onClick={() => setView('home')}
            >
              Gignova
            </Link>
          </NavigationMenuLink>
        </NavigationMenuItem>

        {/* Center: Spacer for equal distribution */}
        <div className="flex-1"></div>

        {/* Right: Actions with equal spacing */}
        <div className="flex items-center gap-6">
          {/* Profile Button */}
          <NavigationMenuItem>
            <Button
              onClick={() => setView('profile')}
              variant="ghost"
              size="sm"
              className="flex items-center gap-2 cursor-pointer"
            >
              <User className="h-4 w-4" />
              Profile
            </Button>
          </NavigationMenuItem>

          {/* zkLogin Authentication */}
          {!isLoading && (
            <NavigationMenuItem>
              {isAuthenticated ? (
                <div className="flex items-center gap-2">
                  <span className="text-sm text-muted-foreground">
                    {walletAddress?.slice(0, 6)}...{walletAddress?.slice(-4)}
                  </span>
                  <Button onClick={logout} variant="outline" size="sm">
                    Logout (zkLogin)
                  </Button>
                </div>
              ) : (
                <Button onClick={login} variant="outline" size="sm">
                  Login with Google (zkLogin)
                </Button>
              )}
            </NavigationMenuItem>
          )}

          {/* Standard Wallet Connect */}
          <NavigationMenuItem>
            <ConnectButton />
          </NavigationMenuItem>
        </div>
      </NavigationMenuList>
    </NavigationMenu>
  );
}