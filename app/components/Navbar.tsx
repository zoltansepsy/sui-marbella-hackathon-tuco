"use client";

import * as React from "react";
import Link from "next/link";
import { ConnectButton } from "@mysten/dapp-kit";
import {
  NavigationMenu,
  NavigationMenuContent,
  NavigationMenuItem,
  NavigationMenuLink,
  NavigationMenuList,
  NavigationMenuTrigger,
  navigationMenuTriggerStyle,
} from "./ui/navigation-menu";
import { useView } from "../contexts/ViewContext";

const platformFeatures: { title: string; view: string; description: string }[] = [
  {
    title: "Job Marketplace",
    view: "marketplace",
    description: "Browse and apply for open freelance jobs.",
  },
  {
    title: "Post a Job",
    view: "createJob",
    description: "Hire talented freelancers for your project.",
  },
  {
    title: "My Jobs",
    view: "myJobs",
    description: "Manage your active and completed jobs.",
  },
  {
    title: "Profile",
    view: "profile",
    description: "View and edit your profile and reputation.",
  },
];

const demoFeatures: { title: string; view: string; description: string }[] = [
  {
    title: "Create Counter",
    view: "createCounter",
    description: "Create a new counter instance on the blockchain.",
  },
  {
    title: "Find Counter",
    view: "search",
    description: "Search for existing counter objects by ID.",
  },
  {
    title: "Walrus Storage",
    view: "walrus",
    description: "Upload files, text, or JSON to Walrus decentralized storage.",
  },
  {
    title: "Seal Whitelist",
    view: "seal",
    description: "Identity-Based Encryption with whitelist access control.",
  },
];

export default function Navbar() {
  const { setView } = useView();

  return (
    <NavigationMenu className="max-w-full justify-between p-4 border-b">
      <NavigationMenuList className="flex w-full justify-between items-center">
        <div className="flex items-center space-x-6">
          <NavigationMenuItem>
            <NavigationMenuLink asChild>
              <Link
                href="/"
                className="flex items-center space-x-2 font-semibold text-lg"
                onClick={() => setView('home')}
              >
                TaskinPool
              </Link>
            </NavigationMenuLink>
          </NavigationMenuItem>

          <NavigationMenuItem>
            <NavigationMenuTrigger>Features</NavigationMenuTrigger>
            <NavigationMenuContent>
              <ul className="grid gap-3 p-6 md:w-[400px] lg:w-[500px] lg:grid-cols-[.75fr_1fr]">
                <li className="row-span-4">
                  <NavigationMenuLink asChild>
                    <Link
                      className="flex h-full w-full select-none flex-col justify-end rounded-md bg-gradient-to-b from-muted/50 to-muted p-6 no-underline outline-none focus:shadow-md"
                      href="/"
                      onClick={() => setView('home')}
                    >
                      <div className="mb-2 mt-4 text-lg font-medium">
                        TaskinPool
                      </div>
                      <p className="text-sm leading-tight text-muted-foreground">
                        Secure freelance work with encrypted deliverables and escrow payments.
                      </p>
                    </Link>
                  </NavigationMenuLink>
                </li>
                {platformFeatures.map((feature) => (
                  <ListItem
                    key={feature.title}
                    title={feature.title}
                    onClick={() => setView(feature.view as any)}
                  >
                    {feature.description}
                  </ListItem>
                ))}
              </ul>
            </NavigationMenuContent>
          </NavigationMenuItem>

          <NavigationMenuItem>
            <NavigationMenuLink asChild className={navigationMenuTriggerStyle()}>
              <Link
                href="/"
                onClick={() => setView('home')}
              >
                Home
              </Link>
            </NavigationMenuLink>
          </NavigationMenuItem>

          <NavigationMenuItem>
            <NavigationMenuLink asChild className={navigationMenuTriggerStyle()}>
              <button
                onClick={() => setView('resources')}
              >
                Resources
              </button>
            </NavigationMenuLink>
          </NavigationMenuItem>
        </div>

        <div className="flex items-center gap-4 ml-auto">
          <NavigationMenuItem>
            <NavigationMenuLink asChild>
              <a
                href="https://sdk.mystenlabs.com/dapp-kit"
                target="_blank"
                rel="noopener noreferrer"
                className="text-sm text-blue-400 hover:text-blue-300 underline"
              >
                📘 dApp Kit
              </a>
            </NavigationMenuLink>
          </NavigationMenuItem>
          <NavigationMenuItem>
          <ConnectButton />
        </NavigationMenuItem>
        </div>
      </NavigationMenuList>
    </NavigationMenu>
  );
}

const ListItem = React.forwardRef<
  React.ElementRef<"button">,
  React.ComponentPropsWithoutRef<"button"> & { title: string; children: React.ReactNode }
>(({ className, title, children, ...props }, ref) => {
  return (
    <li>
      <NavigationMenuLink asChild>
        <button
          ref={ref}
          className={`block w-full text-left select-none space-y-1 rounded-md p-3 leading-none no-underline outline-none transition-colors hover:bg-accent hover:text-accent-foreground focus:bg-accent focus:text-accent-foreground ${className}`}
          {...props}
        >
          <div className="text-sm font-medium leading-none">{title}</div>
          <p className="line-clamp-2 text-sm leading-snug text-muted-foreground">
            {children}
          </p>
        </button>
      </NavigationMenuLink>
    </li>
  );
});
ListItem.displayName = "ListItem";