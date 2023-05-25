Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

# Create the main form
$form = New-Object System.Windows.Forms.Form
$form.Text = "Azure Policy Compliance Scan"
$form.Size = New-Object System.Drawing.Size(500, 840)
$form.StartPosition = "CenterScreen"

# Create a label for subscriptions
$label = New-Object System.Windows.Forms.Label
$label.Location = New-Object System.Drawing.Point(10, 10)
$label.Size = New-Object System.Drawing.Size(200, 20)
$label.Text = "Subscriptions:"
$form.Controls.Add($label)

# Create a list box for subscriptions
$listBox = New-Object System.Windows.Forms.ListBox
$listBox.Location = New-Object System.Drawing.Point(10, 30)
$listBox.Size = New-Object System.Drawing.Size(380, 150)
$form.Controls.Add($listBox)

# Create a label for resource groups
$resourceGroupLabel = New-Object System.Windows.Forms.Label
$resourceGroupLabel.Location = New-Object System.Drawing.Point(10, 190)
$resourceGroupLabel.Size = New-Object System.Drawing.Size(200, 20)
$resourceGroupLabel.Text = "Resource Groups:"
$form.Controls.Add($resourceGroupLabel)

# Create a ComboBox for resource groups
$resourceGroupComboBox = New-Object System.Windows.Forms.ComboBox
$resourceGroupComboBox.Location = New-Object System.Drawing.Point(10, 210)
$resourceGroupComboBox.Size = New-Object System.Drawing.Size(380, 20)
$form.Controls.Add($resourceGroupComboBox)

# Create a button to run the login command
$loginButton = New-Object System.Windows.Forms.Button
$loginButton.Location = New-Object System.Drawing.Point(10, 250)
$loginButton.Size = New-Object System.Drawing.Size(120, 30)
$loginButton.Text = "Login to Azure"
$form.Controls.Add($loginButton)

# Create a button to run the scan command
$scanButton = New-Object System.Windows.Forms.Button
$scanButton.Location = New-Object System.Drawing.Point(140, 250)
$scanButton.Size = New-Object System.Drawing.Size(120, 30)
$scanButton.Text = "Start Scan"
$form.Controls.Add($scanButton)

# Create a button to display the list of running jobs
$jobsButton = New-Object System.Windows.Forms.Button
$jobsButton.Location = New-Object System.Drawing.Point(270, 250)
$jobsButton.Size = New-Object System.Drawing.Size(120, 30)
$jobsButton.Text = "Running Jobs"
$form.Controls.Add($jobsButton)

# Create a button to clear all jobs
$clearJobsButton = New-Object System.Windows.Forms.Button
$clearJobsButton.Location = New-Object System.Drawing.Point(140, 290)
$clearJobsButton.Size = New-Object System.Drawing.Size(120, 30)
$clearJobsButton.Text = "Clear Jobs"
$form.Controls.Add($clearJobsButton)

# Create a ListView control for displaying running jobs
$jobListView = New-Object System.Windows.Forms.ListView
$jobListView.Location = New-Object System.Drawing.Point(10, 330)
$jobListView.Size = New-Object System.Drawing.Size(380, 180)
$jobListView.View = [System.Windows.Forms.View]::Details
$jobListView.FullRowSelect = $true
$form.Controls.Add($jobListView)

# Add columns to the ListView
$jobListView.Columns.Add("Job ID", 100) | Out-Null
$jobListView.Columns.Add("Status", 100) | Out-Null
$jobListView.Columns.Add("Name", 100) | Out-Null
$jobListView.Columns.Add("Command", 100) | Out-Null
$jobListView.Columns.Add("Location", 100) | Out-Null
$jobListView.Columns.Add("Creation Time", 100) | Out-Null

# Create a TextBox control for displaying the output
$outputPane = New-Object System.Windows.Forms.TextBox
$outputPane.Location = New-Object System.Drawing.Point(10, 520)
$outputPane.Size = New-Object System.Drawing.Size(380, 150)
$outputPane.Multiline = $true
$outputPane.ReadOnly = $true
$outputPane.ScrollBars = "Vertical"
$form.Controls.Add($outputPane)

# Create labels for displaying user, tenant, and subscription
$userLabel = New-Object System.Windows.Forms.Label
$userLabel.Location = New-Object System.Drawing.Point(10, 690)
$userLabel.Size = New-Object System.Drawing.Size(380, 20)
$form.Controls.Add($userLabel)

$tenantLabel = New-Object System.Windows.Forms.Label
$tenantLabel.Location = New-Object System.Drawing.Point(10, 710)
$tenantLabel.Size = New-Object System.Drawing.Size(380, 20)
$form.Controls.Add($tenantLabel)

$subscriptionLabel = New-Object System.Windows.Forms.Label
$subscriptionLabel.Location = New-Object System.Drawing.Point(10, 730)
$subscriptionLabel.Size = New-Object System.Drawing.Size(380, 20)
$form.Controls.Add($subscriptionLabel)

# Update the labels with user, tenant, and subscription information
$userLabel.Text = "Logged-in User: $((Get-AzContext).Account.Id)"
$tenantLabel.Text = "Selected Tenant: $((Get-AzContext).Tenant.Id)"
$subscriptionLabel.Text = "Selected Subscription:"

# Read subscriptions from a text file and populate the list box
$subscriptions = Get-Content -Path "C:\Users\ppham\repo\phipcode\powershell\azure-compliance-gui\subscriptions.txt"
$listBox.Items.AddRange($subscriptions)


# Function to populate the ListView with running jobs
function UpdateJobListView {
    $allJobs = Get-Job
    $jobListView.Items.Clear()
    foreach ($job in $allJobs) {
        $jobItem = New-Object System.Windows.Forms.ListViewItem
        $jobItem.Text = $job.Id
        $jobItem.SubItems.Add($job.State)
        $jobItem.SubItems.Add($job.Name)
        $jobItem.SubItems.Add($job.Command)
        $jobItem.SubItems.Add($job.Location)
        #  $jobItem.SubItems.Add($job.Created)
        $jobListView.Items.Add($jobItem)
    }
}

# Update the ListView initially
UpdateJobListView

# Login button click event handler
$loginButton.Add_Click({
        try {
            $outputPane.AppendText("Logging in to Azure...`n")
            Connect-AzAccount -ErrorAction Stop
            $outputPane.AppendText("Login successful`n")
        }
        catch {
            $errorMessage = $_.Exception.Message
            $outputPane.AppendText("Error logging in to Azure:`n")
            $outputPane.AppendText($errorMessage)
            $outputPane.AppendText("`n")
        }
    })

# ListBox SelectedIndexChanged event handler
$listBox.Add_SelectedIndexChanged({
        $selectedSubscription = $listBox.SelectedItem
        if ($selectedSubscription) {
            $outputPane.AppendText("Running Set-AzContext -Subscription $selectedSubscription`n")
            try {
                Set-AzContext -Subscription $selectedSubscription -ErrorAction Stop
                $outputPane.AppendText("Set-AzContext completed successfully`n")

                # Clear the resource group ComboBox
                $resourceGroupComboBox.Items.Clear()

                # Populate the resource group ComboBox
                $resourceGroups = Get-AzResourceGroup | Select-Object -ExpandProperty ResourceGroupName
                $resourceGroupComboBox.Items.AddRange($resourceGroups)
            }
            catch {
                $errorMessage = $_.Exception.Message
                $outputPane.AppendText("Error running commands:`n")
                $outputPane.AppendText($errorMessage)
                $outputPane.AppendText("`n")
            }
        }
    })
# Scan button click event handler
$scanButton.Add_Click({
        $selectedSubscription = $listBox.SelectedItem
        if ($selectedSubscription) {
            $outputPane.AppendText("Running Set-AzContext -Subscription $selectedSubscription`n")

            try {
                Set-AzContext -Subscription $selectedSubscription -ErrorAction Stop
                $outputPane.AppendText("Set-AzContext completed successfully`n")
    
                $selectedResourceGroup = $resourceGroupComboBox.SelectedItem
                if ($selectedResourceGroup) {
                    $command = "Start-AzPolicyComplianceScan -ResourceGroupName '$selectedResourceGroup'"
                    $outputPane.AppendText("Running $command`n")
                    $jobId = (Start-AzPolicyComplianceScan -ResourceGroupName $selectedResourceGroup -AsJob).Id
                }
                else {
                    $command = "Start-AzPolicyComplianceScan"
                    $outputPane.AppendText("Running $command`n")
                    $jobId = (Start-AzPolicyComplianceScan -AsJob).Id
                }
    
                if ($jobId) {
                    $outputPane.AppendText("Started scan job for subscription: $selectedSubscription, Job ID: $jobId`n")
                    $jobItem = New-Object System.Windows.Forms.ListViewItem
                    $jobItem.Text = $jobId
                    $jobItem.SubItems.Add("Running")
                    $jobItem.SubItems.Add("")  # Helper text
                    $jobItem.SubItems.Add($command)  # Display the command in the ListView
                    $jobItem.SubItems.Add((Get-Location).Path)
                    $jobItem.SubItems.Add((Get-Date).ToString())
                    $jobListView.Items.Add($jobItem)
                }
                else {
                    $outputPane.AppendText("Failed to start job`n")
                }
            }
            catch {
                $errorMessage = $_.Exception.Message
                $outputPane.AppendText("Error running commands:`n")
                $outputPane.AppendText($errorMessage)
                $outputPane.AppendText("`n")
            }
    

            UpdateJobListView
        }
        else {
            $outputPane.AppendText("Please select a subscription before starting the scan`n")
        }
    })

# Jobs button click event handler
$jobsButton.Add_Click({
        UpdateJobListView
    })

# Clear Jobs button click event handler
$clearJobsButton.Add_Click({
        $allJobs = Get-Job
        if ($allJobs) {
            $allJobs | Remove-Job -Force
            $outputPane.AppendText("All jobs cleared`n")
        }
        else {
            $outputPane.AppendText("No jobs found`n")
        }
        UpdateJobListView
    })

# Display the form
$form.ShowDialog() | Out-Null