# VeeamTagsVMware
Assess the tags allocated to a VM in Vcenter, When using Veeam to backup your estate using backup jobs that use VMware Tags to assign VM's to a backup job.

If the VM has no tags assign the default tag of 'Replication-No' & the current datastore storage assigned to that VMhost.
If the VM has the name of "*_replica" then assign the tag 'Backup-No Backup' and remove any RPO tag assigned.
If the VM has a tag of 'Replcation-Yes' but has no RPO tag assign a default tag of 'RPO24'.

All VM's will have their current datastore storage tag assessed to see if it is still valid, if it doesn't pass the check it will flag a tag mismatch in the dailychecks.log

Any tags that are missing (or not required because of the previous logic of tag assessment will be display in the Dailychecks.log as "Tag Changes".

Any datastores that don't have tags will be flagged as "Unknown Datastore tag location" in DailyChecks.log

Tag Changes, Tag Mismatches, Storage Tag Warnings will be compiled per host in the log file, the Backup-No Backup is a cumlative for the VM estate and will be displayed at the bottom of the reports.

Recommend using CMTrace to view the dialychecks.log as it will highlight Warnings in Yellow.



