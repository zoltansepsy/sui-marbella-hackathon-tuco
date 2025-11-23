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
import { MyPortfolioView } from "./components/job/MyPortfolioView";
import { JobMarketplaceView } from "./JobMarketplaceView";
import { CreateJobView } from "./components/job/CreateJobView";
import { ClientJobDetailView } from "./components/job/ClientJobDetailView";
import { FreelancerJobDetailView } from "./components/job/FreelancerJobDetailView";
import { ProfileView } from "./components/profile/ProfileView";
import { Card, CardContent } from "@/components/ui/card";
import { Button } from "@/components/ui/button";
import { useView } from "./contexts/ViewContext";
import { useCurrentProfile } from "./hooks/useProfile";
import { ProfileType } from "./services/types";

export default function Home() {
  const currentAccount = useCurrentAccount();
  const [counterId, setCounter] = useState<string | null>(null);
  const { view, setView, selectedJobId, setSelectedJobId } = useView();
  const { profile } = useCurrentProfile();
  // Track which view the job detail was opened from (client or freelancer context)
  const [jobDetailOrigin, setJobDetailOrigin] = useState<"myJobs" | "myPortfolio">("myJobs");


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
                          Gignova
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
                        

                        <Card className="p-6 hover:shadow-lg transition-shadow cursor-pointer" onClick={() => setView("myPortfolio")}>
                          <h3 className="text-2xl font-semibold mb-3">
                            My Portfolio
                          </h3>
                          <p className="text-muted-foreground mb-4">
                            Track your assigned jobs and work progress
                          </p>
                          <Button className="w-full bg-orange-600 hover:bg-orange-700 text-white">
                            View My Portfolio
                          </Button>
                        </Card>
                        
                      </div>
                    </div>
                  )}

                  {/* Freelance Platform Views */}
                  {view === "marketplace" && (
                    <JobMarketplaceView onBack={() => setView("home")} />
                  )}

                  {view === "myJobs" && (
                    <MyJobsView
                      onBack={() => setView("home")}
                      onViewJob={(jobId) => {
                        setJobDetailOrigin("myJobs");
                        setSelectedJobId?.(jobId);
                        setView("jobDetail");
                      }}
                    />
                  )}

                  {view === "myPortfolio" && (
                    <MyPortfolioView
                      onBack={() => setView("home")}
                      onViewJob={(jobId) => {
                        setJobDetailOrigin("myPortfolio");
                        setSelectedJobId?.(jobId);
                        setView("jobDetail");
                      }}
                    />
                  )}

                  {view === "createJob" && (
                    <CreateJobView
                      onBack={() => setView("home")}
                      onSuccess={(jobId) => {
                        console.log("Job created:", jobId);
                        setView("marketplace");
                      }}
                    />
                  )}

                  {view === "profile" && (
                    <ProfileView
                      onBack={() => setView("home")}
                      onCreateProfile={() => {
                        // TODO: Navigate to profile creation
                        console.log("Create profile");
                      }}
                    />
                  )}

                  {view === "jobDetail" && selectedJobId && (
                    <>
                      {jobDetailOrigin === "myJobs" ? (
                        <ClientJobDetailView
                          jobId={selectedJobId}
                          onBack={() => {
                            setSelectedJobId?.("");
                            setView("myJobs");
                          }}
                        />
                      ) : (
                        <FreelancerJobDetailView
                          jobId={selectedJobId}
                          onBack={() => {
                            setSelectedJobId?.("");
                            setView("myPortfolio");
                          }}
                        />
                      )}
                    </>
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
                      Welcome to Gignova
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
