import sys, os, re, subprocess

input_directory = '/media/labs/rsmith/lab-members/cgoldman/go_no_go/DDM/processed_behavioral_files_DDM'
results = sys.argv[1]

if not os.path.exists(results):
    os.makedirs(results)
    print(f"Created results directory {results}")

if not os.path.exists(f"{results}/logs"):
    os.makedirs(f"{results}/logs")
    print(f"Created results-logs directory {results}/logs")

# subjects is an array of filenames
subjects = [os.path.join(input_directory, filename) for filename in os.listdir(input_directory) if filename.endswith('.csv')]

ssub_path = '/media/labs/rsmith/lab-members/cgoldman/go_no_go/DDM/RL_DDM_Millner/RL_DDM-CMG/run_RL_DDM.ssub'

for subject in subjects:
    # get the subject name from the filename
    pattern = r'(.{5})_processed_behavioral_file'
    match = re.search(pattern, subject)
    subject_name = match.group(1)

    stdout_name = f"{results}/logs/{subject_name}-%J.stdout"
    stderr_name = f"{results}/logs/{subject_name}-%J.stderr"

    jobname = f'GNG_RLDDM-fit-{subject_name}'
    os.system(f"sbatch -J {jobname} -o {stdout_name} -e {stderr_name} {ssub_path} {subject} {results}")

    print(f"SUBMITTED JOB [{jobname}]")


    ###python3 run_RL_DDM.py /media/labs/rsmith/lab-members/cgoldman/go_no_go/DDM/RL_DDM_Millner/RL_DDM_fits