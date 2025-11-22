"use client";
import { useCurrentAccount } from "@mysten/dapp-kit";
import { isValidSuiObjectId } from "@mysten/sui/utils";
import { useState, useEffect } from "react";
import { Counter } from "./Counter";
import { CreateCounter } from "./CreateCounter";
import { CounterList } from "./components/CounterList";
import { WalrusUpload } from "./WalrusUpload";
import { SealWhitelist } from "./SealWhitelist";
import { Resources } from "./Resources";
import { MyJobsView } from "./components/job/MyJobsView";
import { Card, CardContent } from "@/components/ui/card";
import { Button } from "@/components/ui/button";
import { useView } from "./contexts/ViewContext";

export default function Home() {
  const currentAccount = useCurrentAccount();
  const [counterId, setCounter] = useState<string | null>(null);
  const { view, setView } = useView();

  useEffect(() => {
    const hash = window.location.hash.slice(1);
    if (isValidSuiObjectId(hash)) {
      setCounter(hash);
      setView("counter");
    }
  }, [setView]);

  const handleCounterCreated = (id: string) => {
    window.location.hash = id;
    setCounter(id);
    setView("counter");
  };

  const handleCounterSelected = (id: string) => {
    window.location.hash = id;
    setCounter(id);
    setView("counter");
  };

  const goBackToSelection = () => {
    setCounter(null);
    setView("home");
    window.location.hash = "";
  };

  return (
    <div className="min-h-screen">
      <div className="container mx-auto p-6">
        <Card className="min-h-[500px]">
          <CardContent className="pt-6">
            {currentAccount ? (
              counterId ? (
                <div className="space-y-4">
                  {/* Back button when viewing a counter */}
                  <div className="flex justify-between items-center">
                    <Button
                      onClick={goBackToSelection}
                      variant="outline"
                    >
                      ← Back to Counter Selection
                    </Button>
                    <div className="text-sm text-muted-foreground">
                      Counter ID: {counterId.slice(0, 8)}...{counterId.slice(-8)}
                    </div>
                  </div>

                  {/* Counter component */}
                  <Counter id={counterId} />
                </div>
              ) : (
                <div className="space-y-6">
                  {/* Content based on view */}
                  {view === "resources" && <Resources />}

                  {view === "home" && (
                    <div className="space-y-6">
                      {/* Welcome Section */}
                      <div className="text-center py-8">
                        <h1 className="text-4xl font-bold mb-4">
                          TaskinPool
                        </h1>
                        <p className="text-lg text-muted-foreground mb-8">
                          Secure freelance work with encrypted deliverables and escrow payments
                        </p>
                      </div>

                      {/* Main Feature Navigation */}
                      <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
                        <Card className="p-6 hover:shadow-lg transition-shadow cursor-pointer" onClick={() => setView("marketplace")}>
                          <h3 className="text-2xl font-semibold mb-3">
                            Job Marketplace
                          </h3>
                          <p className="text-muted-foreground mb-4">
                            Browse and apply for open freelance jobs
                          </p>
                          <Button className="w-full bg-blue-600 hover:bg-blue-700 text-white">
                            Browse Jobs
                          </Button>
                        </Card>

                        <Card className="p-6 hover:shadow-lg transition-shadow cursor-pointer" onClick={() => setView("createJob")}>
                          <h3 className="text-2xl font-semibold mb-3">
                            Post a Job
                          </h3>
                          <p className="text-muted-foreground mb-4">
                            Hire talented freelancers for your project
                          </p>
                          <Button className="w-full bg-green-600 hover:bg-green-700 text-white">
                            Create Job
                          </Button>
                        </Card>

                        <Card className="p-6 hover:shadow-lg transition-shadow cursor-pointer" onClick={() => setView("myJobs")}>
                          <h3 className="text-2xl font-semibold mb-3">
                            My Posted Jobs
                          </h3>
                          <p className="text-muted-foreground mb-4">
                            Manage your active and completed jobs
                          </p>
                          <Button className="w-full bg-purple-600 hover:bg-purple-700 text-white">
                            View My Posted Jobs
                          </Button>
                        </Card>

                        <Card className="p-6 hover:shadow-lg transition-shadow cursor-pointer" onClick={() => setView("profile")}>
                          <h3 className="text-2xl font-semibold mb-3">
                            Profile
                          </h3>
                          <p className="text-muted-foreground mb-4">
                            View and edit your profile, reputation, and badges
                          </p>
                          <Button className="w-full bg-indigo-600 hover:bg-indigo-700 text-white">
                            View Profile
                          </Button>
                        </Card>
                      </div>

                      {/* Demo Features Section */}
                      <div className="mt-12 pt-8 border-t">
                        <h3 className="text-lg font-semibold mb-4">Demo Features</h3>
                        <div className="grid grid-cols-1 md:grid-cols-3 gap-4">
                          <Card className="p-4">
                            <h4 className="text-md font-semibold mb-2">Counter</h4>
                            <div className="flex flex-col gap-2">
                              <Button onClick={() => setView("createCounter")} variant="outline" size="sm">
                                Create Counter
                              </Button>
                              <Button onClick={() => setView("search")} variant="outline" size="sm">
                                Find Counter
                              </Button>
                            </div>
                          </Card>
                          <Card className="p-4">
                            <h4 className="text-md font-semibold mb-2">Walrus Storage</h4>
                            <Button onClick={() => setView("walrus")} variant="outline" size="sm" className="w-full">
                              Upload Files
                            </Button>
                          </Card>
                          <Card className="p-4">
                            <h4 className="text-md font-semibold mb-2">Seal Encryption</h4>
                            <Button onClick={() => setView("seal")} variant="outline" size="sm" className="w-full">
                              Seal Whitelist
                            </Button>
                          </Card>
                        </div>
                      </div>
                    </div>
                  )}

                  {/* Freelance Platform Views */}
                  {view === "marketplace" && (
                    <div className="text-center py-12">
                      <h2 className="text-2xl font-bold mb-4">Job Marketplace</h2>
                      <p className="text-muted-foreground mb-4">Browse open freelance jobs (Coming Soon)</p>
                      <p className="text-sm text-muted-foreground">DEV 3: Implement JobMarketplaceView component</p>
                      <Button onClick={() => setView("home")} className="mt-4">Back to Home</Button>
                    </div>
                  )}

                  {view === "myJobs" && (
                    <MyJobsView
                      onBack={() => setView("home")}
                      onViewJob={(jobId) => {
                        // TODO: Navigate to job detail view
                        console.log("View job:", jobId);
                        setView("jobDetail");
                      }}
                    />
                  )}

                  {view === "createJob" && (
                    <div className="text-center py-12">
                      <h2 className="text-2xl font-bold mb-4">Create Job</h2>
                      <p className="text-muted-foreground mb-4">Post a new job (Coming Soon)</p>
                      <p className="text-sm text-muted-foreground">DEV 3: Implement CreateJobView component</p>
                      <Button onClick={() => setView("home")} className="mt-4">Back to Home</Button>
                    </div>
                  )}

                  {view === "profile" && (
                    <div className="text-center py-12">
                      <h2 className="text-2xl font-bold mb-4">Profile</h2>
                      <p className="text-muted-foreground mb-4">View and edit your profile (Coming Soon)</p>
                      <p className="text-sm text-muted-foreground">DEV 3: Implement ProfileView component</p>
                      <Button onClick={() => setView("home")} className="mt-4">Back to Home</Button>
                    </div>
                  )}

                  {view === "jobDetail" && (
                    <div className="text-center py-12">
                      <h2 className="text-2xl font-bold mb-4">Job Details</h2>
                      <p className="text-muted-foreground mb-4">View job details (Coming Soon)</p>
                      <p className="text-sm text-muted-foreground">DEV 3: Implement JobDetailView component</p>
                      <Button onClick={() => setView("marketplace")} className="mt-4">Back to Marketplace</Button>
                    </div>
                  )}

                  {view === "createCounter" && (
                    <CreateCounter onCreated={handleCounterCreated} />
                  )}

                  {view === "search" && (
                    <CounterList onSelectCounter={handleCounterSelected} />
                  )}

                  {view === "walrus" && <WalrusUpload />}

                  {view === "seal" && <SealWhitelist />}
                </div>
              )
            ) : (
              <div className="space-y-6">
                {view === "resources" ? (
                  <Resources />
                ) : (
                  <div className="text-center py-12">
                    <h2 className="text-xl font-semibold mb-2">
                      Welcome to TaskinPool
                    </h2>
                    <p className="text-muted-foreground mb-4">
                      Please connect your wallet to get started
                    </p>
                    <p className="text-sm text-muted-foreground">
                      All documentation and resources are available in the{" "}
                      <strong>Resources</strong> tab in the navigation bar.
                    </p>
                  </div>
                )}
              </div>
            )}
          </CardContent>
        </Card>
      </div>
    </div>
  );
}
