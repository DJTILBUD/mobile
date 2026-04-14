import 'package:dj_tilbud_app/features/jobs/domain/entities/dj_quote.dart';
import 'package:dj_tilbud_app/features/jobs/domain/entities/ext_job.dart';
import 'package:dj_tilbud_app/features/jobs/domain/entities/job.dart';
import 'package:dj_tilbud_app/features/jobs/domain/entities/service_offer.dart';

/// Represents a pending action the user must take on a won job.
/// Mirrors the web app's action-notification logic exactly.
enum JobActionType {
  /// Red — contact the customer now, no planned date set.
  contactCustomer,

  /// Amber — a planned contact date has been set.
  contactCustomerPlanned,

  /// Red — customer contacted; move the job to ready_for_billing.
  moveToReady,

  /// Red — event is within 5 days, must confirm ready.
  confirmReady,
}

// ─── DJ internal quotes ───────────────────────────────────────────────────────

extension DjQuoteAction on DjQuote {
  JobActionType? get pendingAction {
    if (status != QuoteStatus.won) return null;
    final jobStatus = job.status;

    if (jobStatus == JobStatus.closed) {
      if (job.customerContactPlannedFor != null) {
        return JobActionType.contactCustomerPlanned;
      }
      return JobActionType.contactCustomer;
    }

    if (jobStatus == JobStatus.customerContacted) {
      return JobActionType.moveToReady;
    }

    if (jobStatus == JobStatus.readyForBilling) {
      if (djReadyConfirmedAt != null) return null;
      if (job.date.difference(DateTime.now()).inDays <= 5) {
        return JobActionType.confirmReady;
      }
    }

    return null;
  }

  bool get hasAction => pendingAction != null;
}

// ─── DJ external jobs ─────────────────────────────────────────────────────────

extension ExtJobAction on ExtJob {
  JobActionType? get pendingAction {
    if (status == ExtJobStatus.closed) {
      if (customerContactPlannedFor != null) {
        return JobActionType.contactCustomerPlanned;
      }
      return JobActionType.contactCustomer;
    }

    if (status == ExtJobStatus.customerContacted) {
      return JobActionType.moveToReady;
    }

    if (status == ExtJobStatus.readyForBilling) {
      if (djReadyConfirmedAt != null) return null;
      if (date.difference(DateTime.now()).inDays <= 5) {
        return JobActionType.confirmReady;
      }
    }

    return null;
  }

  bool get hasAction => pendingAction != null;
}

// ─── Musician service offers ──────────────────────────────────────────────────

extension ServiceOfferAction on ServiceOffer {
  static const _eligibleStatuses = [
    JobStatus.closed,
    JobStatus.customerContacted,
    JobStatus.readyForBilling,
  ];

  JobActionType? get pendingAction {
    if (status != ServiceOfferStatus.won) return null;
    if (!_eligibleStatuses.contains(job.status)) return null;

    if (!customerContacted) {
      if (customerContactPlannedFor != null) {
        return JobActionType.contactCustomerPlanned;
      }
      return JobActionType.contactCustomer;
    }

    if (musicianReadyConfirmedAt == null) {
      if (job.date.difference(DateTime.now()).inDays <= 5) {
        return JobActionType.confirmReady;
      }
    }

    return null;
  }

  bool get hasAction => pendingAction != null;
}
