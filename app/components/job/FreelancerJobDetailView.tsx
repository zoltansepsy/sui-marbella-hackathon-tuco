/**
 * Freelancer Job Detail View Component
 * Displays job details with freelancer-specific actions for managing assigned jobs
 *
 * Features:
 * - State-based action buttons (start work, submit milestone)
 * - Milestone tracking
 * - Client information
 * - Approval status for submitted work
 * - Payment info for completed jobs
 */

"use client";

import { useState, useMemo } from "react";
import { useJob } from "@/hooks";
import { JobData, JobState } from "@/services/types";
import { createJobService } from "@/services";
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from "@/components/ui/card";
import { Button } from "@/components/ui/button";
import { Badge } from "@/components/ui/badge";
import { Alert, AlertDescription } from "@/components/ui/alert";
import {
  Calendar,
  DollarSign,
  User,
  Clock,
  CheckCircle,
  AlertCircle,
  FileText,
  Target,
  ArrowLeft,
  Play,
  Upload,
  Download,
} from "lucide-react";
import { useCurrentAccount, useSignAndExecuteTransaction, useSuiClient } from "@mysten/dapp-kit";
import { useNetworkVariable } from "../../networkConfig";
import {
  formatSUI,
  formatDeadline,
  formatDate,
  shortenAddress,
  isDeadlineApproaching,
  isDeadlinePassed,
} from "@/utils";

interface FreelancerJobDetailViewProps {
  jobId: string;
  onBack: () => void;
}

export function FreelancerJobDetailView({ jobId, onBack }: FreelancerJobDetailViewProps) {
  const currentAccount = useCurrentAccount();
  const suiClient = useSuiClient();
  const jobPackageId = useNetworkVariable("jobEscrowPackageId");
  const { mutate: signAndExecute } = useSignAndExecuteTransaction();

  const { job, isPending, error, refetch } = useJob(jobId);

  // State for actions
  const [isWorking, setIsWorking] = useState(false);
  const [actionError, setActionError] = useState<string | null>(null);
  const [actionSuccess, setActionSuccess] = useState<string | null>(null);

  const jobService = useMemo(
    () => createJobService(suiClient, jobPackageId),
    [suiClient, jobPackageId]
  );

  // Check if current user is the freelancer
  const isFreelancer = useMemo(() => {
    if (!job || !currentAccount) return false;

    // MOCK DATA: If freelancer address is the placeholder, allow any user (for demo)
    if (job.freelancer === "0xf000000000000000000000000000000000000000000000000000000000000000") {
      console.log("🎭 MOCK: Allowing freelancer access for demo purposes");
      return true;
    }

    return job.freelancer === currentAccount.address;
  }, [job, currentAccount]);

  // Handle start work
  const handleStartWork = async () => {
    if (!job || !currentAccount) return;

    setIsWorking(true);
    setActionError(null);
    setActionSuccess(null);

    try {
      const tx = jobService.startJobTransaction(jobId);

      signAndExecute(
        { transaction: tx },
        {
          onSuccess: async ({ digest }) => {
            await suiClient.waitForTransaction({ digest });
            setIsWorking(false);
            setActionSuccess("Work started successfully!");
            refetch();

            setTimeout(() => {
              setActionSuccess(null);
            }, 3000);
          },
          onError: (error) => {
            console.error("Error starting work:", error);
            setActionError(error.message || "Failed to start work");
            setIsWorking(false);
          },
        }
      );
    } catch (error: any) {
      console.error("Error starting work:", error);
      setActionError(error.message || "Failed to start work");
      setIsWorking(false);
    }
  };

  // Get state badge
  const getStateBadge = (state: JobState) => {
    switch (state) {
      case JobState.ASSIGNED:
        return { variant: "secondary" as const, label: "ASSIGNED", color: "bg-blue-100 text-blue-800" };
      case JobState.IN_PROGRESS:
        return { variant: "default" as const, label: "IN PROGRESS", color: "bg-yellow-100 text-yellow-800" };
      case JobState.SUBMITTED:
      case JobState.AWAITING_REVIEW:
        return { variant: "warning" as const, label: "AWAITING REVIEW", color: "bg-orange-100 text-orange-800" };
      case JobState.COMPLETED:
        return { variant: "secondary" as const, label: "COMPLETED", color: "bg-green-100 text-green-800" };
      case JobState.CANCELLED:
        return { variant: "destructive" as const, label: "CANCELLED", color: "bg-red-100 text-red-800" };
      default:
        return { variant: "default" as const, label: JobState[state], color: "bg-gray-100 text-gray-800" };
    }
  };

  if (isPending) {
    return (
      <div className="py-8 text-center">
        <div className="animate-spin rounded-full h-12 w-12 border-b-2 border-primary mx-auto"></div>
        <p className="mt-4 text-muted-foreground">Loading job details...</p>
      </div>
    );
  }

  if (error) {
    return (
      <div className="py-8">
        <Alert variant="destructive">
          <AlertCircle className="h-4 w-4" />
          <AlertDescription>Error loading job: {error.message}</AlertDescription>
        </Alert>
        <div className="mt-4 text-center">
          <Button onClick={() => refetch()} variant="outline">
            Retry
          </Button>
          <Button onClick={onBack} variant="ghost" className="ml-2">
            Back
          </Button>
        </div>
      </div>
    );
  }

  if (!job) {
    return (
      <div className="py-8 text-center">
        <p className="text-muted-foreground">Job not found</p>
        <Button onClick={onBack} variant="outline" className="mt-4">
          Back
        </Button>
      </div>
    );
  }

  if (!isFreelancer) {
    return (
      <div className="py-8 text-center">
        <Alert variant="destructive">
          <AlertCircle className="h-4 w-4" />
          <AlertDescription>You are not assigned to this job</AlertDescription>
        </Alert>
        <Button onClick={onBack} variant="outline" className="mt-4">
          Back
        </Button>
      </div>
    );
  }

  const badge = getStateBadge(job.state);

  return (
    <div className="space-y-6">
      {/* Header with Back Button */}
      <div className="flex items-center gap-4">
        <Button onClick={onBack} variant="outline" size="sm">
          <ArrowLeft className="h-4 w-4 mr-2" />
          Back to Portfolio
        </Button>
      </div>

      {/* Job Title and Status */}
      <Card>
        <CardHeader>
          <div className="flex items-start justify-between">
            <div className="flex-1">
              <CardTitle className="text-2xl mb-2">{job.title}</CardTitle>
              <CardDescription className="flex items-center gap-2 flex-wrap">
                <Badge variant={badge.variant} className={badge.color}>
                  {badge.label}
                </Badge>
                {isDeadlineApproaching(job.deadline) && !isDeadlinePassed(job.deadline) && (
                  <Badge variant="warning">Urgent</Badge>
                )}
                {isDeadlinePassed(job.deadline) && job.state !== JobState.COMPLETED && (
                  <Badge variant="destructive">Deadline Passed</Badge>
                )}
              </CardDescription>
            </div>
          </div>
        </CardHeader>
      </Card>

      {/* Success/Error Messages */}
      {actionSuccess && (
        <Alert className="bg-green-50 border-green-200">
          <CheckCircle className="h-4 w-4 text-green-600" />
          <AlertDescription className="text-green-800">{actionSuccess}</AlertDescription>
        </Alert>
      )}

      {actionError && (
        <Alert variant="destructive">
          <AlertCircle className="h-4 w-4" />
          <AlertDescription>{actionError}</AlertDescription>
        </Alert>
      )}

      {/* Key Information Grid */}
      <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
        <Card>
          <CardContent className="pt-6">
            <div className="flex items-center gap-3">
              <DollarSign className="h-5 w-5 text-green-600" />
              <div>
                <p className="text-sm text-muted-foreground">Payment</p>
                <p className="text-xl font-bold">{formatSUI(job.budget)}</p>
              </div>
            </div>
          </CardContent>
        </Card>

        <Card>
          <CardContent className="pt-6">
            <div className="flex items-center gap-3">
              <Calendar className="h-5 w-5 text-blue-600" />
              <div>
                <p className="text-sm text-muted-foreground">Deadline</p>
                <p className="text-lg font-semibold">{formatDate(job.deadline)}</p>
                <p className="text-xs text-muted-foreground">{formatDeadline(job.deadline)}</p>
              </div>
            </div>
          </CardContent>
        </Card>

        <Card>
          <CardContent className="pt-6">
            <div className="flex items-center gap-3">
              <User className="h-5 w-5 text-purple-600" />
              <div>
                <p className="text-sm text-muted-foreground">Client</p>
                <p className="text-sm font-mono">{shortenAddress(job.client)}</p>
              </div>
            </div>
          </CardContent>
        </Card>

        <Card>
          <CardContent className="pt-6">
            <div className="flex items-center gap-3">
              <Target className="h-5 w-5 text-orange-600" />
              <div>
                <p className="text-sm text-muted-foreground">Milestones</p>
                <p className="text-xl font-bold">{job.milestoneCount}</p>
              </div>
            </div>
          </CardContent>
        </Card>
      </div>

      {/* Description */}
      <Card>
        <CardHeader>
          <CardTitle className="flex items-center gap-2">
            <FileText className="h-5 w-5" />
            Job Description
          </CardTitle>
        </CardHeader>
        <CardContent>
          <div className="prose prose-sm max-w-none">
            <p className="text-sm text-muted-foreground">
              Blob ID: <span className="font-mono text-xs">{job.descriptionBlobId}</span>
            </p>
            <p className="mt-2 text-muted-foreground">
              (Description stored on Walrus - integration pending)
            </p>
          </div>
        </CardContent>
      </Card>

      {/* State-Specific Content */}

      {/* ASSIGNED State: Start Work */}
      {job.state === JobState.ASSIGNED && (
        <Card className="border-blue-200 bg-blue-50">
          <CardHeader>
            <CardTitle className="text-blue-800">Ready to Start</CardTitle>
            <CardDescription>Begin work on this job</CardDescription>
          </CardHeader>
          <CardContent>
            <Alert className="bg-white border-blue-300 mb-4">
              <AlertCircle className="h-4 w-4 text-blue-600" />
              <AlertDescription className="text-blue-800">
                Once you start, the job state will change to "In Progress"
              </AlertDescription>
            </Alert>
            <Button
              onClick={handleStartWork}
              disabled={isWorking}
              className="bg-blue-600 hover:bg-blue-700"
            >
              {isWorking ? (
                <>
                  <div className="animate-spin rounded-full h-4 w-4 border-b-2 border-white mr-2"></div>
                  Starting...
                </>
              ) : (
                <>
                  <Play className="h-4 w-4 mr-2" />
                  Start Work
                </>
              )}
            </Button>
          </CardContent>
        </Card>
      )}

      {/* IN_PROGRESS State: Submit Milestone */}
      {job.state === JobState.IN_PROGRESS && (
        <Card className="border-yellow-200 bg-yellow-50">
          <CardHeader>
            <CardTitle className="text-yellow-800">Work in Progress</CardTitle>
            <CardDescription>Submit your work when ready</CardDescription>
          </CardHeader>
          <CardContent>
            <Alert className="bg-white border-yellow-300 mb-4">
              <AlertCircle className="h-4 w-4 text-yellow-600" />
              <AlertDescription className="text-yellow-800">
                Upload your deliverables and submit for client review
              </AlertDescription>
            </Alert>
            <Button className="bg-yellow-600 hover:bg-yellow-700">
              <Upload className="h-4 w-4 mr-2" />
              Submit Milestone (Coming Soon)
            </Button>
          </CardContent>
        </Card>
      )}

      {/* SUBMITTED/AWAITING_REVIEW: Waiting for Approval */}
      {(job.state === JobState.SUBMITTED || job.state === JobState.AWAITING_REVIEW) && (
        <Card className="border-orange-200 bg-orange-50">
          <CardHeader>
            <CardTitle className="text-orange-800">Awaiting Client Review</CardTitle>
            <CardDescription>Your work has been submitted</CardDescription>
          </CardHeader>
          <CardContent>
            <Alert className="bg-white border-orange-300">
              <Clock className="h-4 w-4 text-orange-600" />
              <AlertDescription className="text-orange-800">
                The client is reviewing your submission. You'll be notified when they approve or request changes.
              </AlertDescription>
            </Alert>

            {job.deliverableBlobIds.length > 0 && (
              <div className="mt-4">
                <p className="text-sm font-medium mb-2">Your Submission:</p>
                {job.deliverableBlobIds.map((blobId, index) => (
                  <p key={index} className="text-xs font-mono text-muted-foreground">
                    Deliverable {index + 1}: {blobId}
                  </p>
                ))}
              </div>
            )}
          </CardContent>
        </Card>
      )}

      {/* COMPLETED: Show Payment Info */}
      {job.state === JobState.COMPLETED && (
        <Card className="border-green-200 bg-green-50">
          <CardHeader>
            <CardTitle className="text-green-800">Job Completed!</CardTitle>
            <CardDescription>Payment has been released</CardDescription>
          </CardHeader>
          <CardContent>
            <div className="space-y-4">
              <Alert className="bg-white border-green-300">
                <CheckCircle className="h-4 w-4 text-green-600" />
                <AlertDescription className="text-green-800">
                  Congratulations! The client approved your work and payment of {formatSUI(job.budget)} has been released to your wallet.
                </AlertDescription>
              </Alert>

              {job.deliverableBlobIds.length > 0 && (
                <div>
                  <p className="text-sm font-medium mb-2">Deliverables:</p>
                  {job.deliverableBlobIds.map((blobId, index) => (
                    <div key={index} className="flex items-center justify-between p-2 border rounded mb-2">
                      <p className="text-xs font-mono">{blobId}</p>
                      <Button size="sm" variant="outline">
                        <Download className="h-3 w-3 mr-1" />
                        View
                      </Button>
                    </div>
                  ))}
                </div>
              )}
            </div>
          </CardContent>
        </Card>
      )}

      {/* CANCELLED: Show Cancellation Info */}
      {job.state === JobState.CANCELLED && (
        <Card className="border-red-200 bg-red-50">
          <CardHeader>
            <CardTitle className="text-red-800">Job Cancelled</CardTitle>
          </CardHeader>
          <CardContent>
            <Alert className="bg-white border-red-300">
              <AlertCircle className="h-4 w-4 text-red-600" />
              <AlertDescription className="text-red-800">
                This job has been cancelled by the client.
              </AlertDescription>
            </Alert>
          </CardContent>
        </Card>
      )}
    </div>
  );
}
