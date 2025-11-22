/**
 * JobCard Component
 * Displays a job summary card for listings
 *
 * DEV 3 TODO:
 * 1. Implement job data display
 * 2. Add state badge (Open, In Progress, etc.)
 * 3. Add budget and deadline display
 * 4. Add click handler for navigation to job detail
 * 5. Add responsive design
 * 6. Add loading skeleton
 */

"use client";

import { Card, CardContent, CardDescription, CardHeader, CardTitle } from "../ui/card";
import { Badge } from "../ui/badge";
import { Button } from "../ui/button";
import { type JobData, JobState } from "../../services";

interface JobCardProps {
  job: JobData;
  onClick?: () => void;
}

export function JobCard({ job, onClick }: JobCardProps) {
  // TODO: Implement formatting helpers
  const formatBudget = (amount: number) => {
    return `${(amount / 1_000_000_000).toFixed(2)} SUI`;
  };

  const formatDeadline = (timestamp: number) => {
    return new Date(timestamp).toLocaleDateString();
  };

  const getStateBadgeVariant = (state: JobState): "default" | "success" | "warning" | "info" | "secondary" | "destructive" => {
    switch (state) {
      case JobState.OPEN:
      case JobState.ASSIGNED:
        return "success";
      case JobState.IN_PROGRESS:
      case JobState.SUBMITTED:
      case JobState.AWAITING_REVIEW:
        return "info";
      case JobState.COMPLETED:
        return "secondary";
      case JobState.CANCELLED:
      case JobState.DISPUTED:
        return "destructive";
      default:
        return "default";
    }
  };

  return (
    <Card className="cursor-pointer hover:shadow-lg transition-shadow" onClick={onClick}>
      <CardHeader>
        <div className="flex justify-between items-start">
          <CardTitle className="text-lg">{job.title}</CardTitle>
          <Badge variant={getStateBadgeVariant(job.state)}>
            {JobState[job.state]}
          </Badge>
        </div>
        <CardDescription>
          Posted by: {job.client.slice(0, 6)}...{job.client.slice(-4)}
        </CardDescription>
      </CardHeader>
      <CardContent>
        <div className="space-y-2">
          <div className="flex justify-between text-sm">
            <span className="text-muted-foreground">Budget:</span>
            <span className="font-semibold">{formatBudget(job.budget)}</span>
          </div>
          <div className="flex justify-between text-sm">
            <span className="text-muted-foreground">Deadline:</span>
            <span>{formatDeadline(job.deadline)}</span>
          </div>
          <div className="flex justify-between text-sm">
            <span className="text-muted-foreground">Milestones:</span>
            <span>{job.milestoneCount}</span>
          </div>
          {job.applicants.length > 0 && (
            <div className="flex justify-between text-sm">
              <span className="text-muted-foreground">Applicants:</span>
              <span>{job.applicants.length}</span>
            </div>
          )}
        </div>
        {/* TODO: Add action buttons based on user role and job state */}
        <Button className="w-full mt-4" variant="outline">
          View Details
        </Button>
      </CardContent>
    </Card>
  );
}
