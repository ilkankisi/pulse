namespace Pulse.Api.Domain;

public enum ReportTargetTypePersistence
{
    Post = 0,
    User = 1
}

public enum ReportReasonPersistence
{
    Spam = 0,
    Harassment = 1,
    HateSpeech = 2,
    Violence = 3,
    SexualContent = 4,
    Impersonation = 5,
    Other = 6
}

public enum ReportStatusPersistence
{
    Pending = 0,
    Resolved = 1,
    Dismissed = 2
}

public enum ModerationActionPersistence
{
    NoAction = 0,
    RemovePost = 1
}