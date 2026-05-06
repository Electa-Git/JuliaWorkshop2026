# Writing Clean and Fast Code in Julia - Workshop 2026
Material for the Julia workshop organised by Lucas Bex, Matteo Rossini, and Jeroen Tant for the IEEE SB Leuven PES Chapter.

We do not assume any familiarity with git whatsoever. 
If you have not used git before, please follow the manual installation instructions and disregard any git-related sections of this README.

## Before the Workshop
Before attending the workshop, please follow the steps below to ensure you have a fully functioning Julia installation and can run the scripts in this repository.
We will not go over these steps during the workshop itself.

### Install Julia
[Install Julia on your machine](https://julialang.org/downloads/) and verify that it works.
Please use **version 1.12.0 or later** to ensure the workshop works smoothly.
Verify your installation by running the following in your terminal:
```
julia --version
```

If this is your first time installing Julia, it is a good idea to initialise the registry by running
```
julia -e "using Pkg; Pkg.instantiate()"
```

### Download this repository
Use one of the following methods to download this repository. 
The repository may be updated before the workshop. 
If so, download the latest version again (or pull the latest changes if using git).

#### Manually
Click on the green *Code* button in the Github user interface.
Select *Download zip*.
To update, simply download the zip again.

#### Git
Download with git using the following command:
```
git clone https://github.com/electa-git/juliaworkshop2026.git
```

To update the repository, run the following commands inside the project.
Note that this will delete any changes you made to the repository on your computer.
```
git reset --hard
git pull
```

### Verify that you can run the scripts
From the repository root run:
```
cd baseline/scripts
julia --project -e "using Pkg; Pkg.resolve(); Pkg.instantiate()"
julia --project run.jl
```
This will install dependencies on your computer and run the baseline example. 
This may take some time.
Afterwards, the files `result.csv` and `plot.png` should be available for your inspection.
If you get an error message, please contact the workshop organiser for support.

## During the workshop
The workshop will feature multiple example scripts, which you can run yourself.
Each script is presented in this repository in its own subfolder on the main branch.
Each example has the following structure:
```
|- Project.toml     # Optional, project file for the package we develop in the example
|- src              # Optional, package files used in this example
   |- ...
|- scripts
   |- Manifest.toml # Manifest file for the simulation script
   |- Project.toml  # Project file for the simulation script
   |- run.jl        # The main simulation script that we will use
   |- ...           # Config files etc.
```

To run the main simulation script of any example, navigate to the script folder and run:
```
julia --project run.jl
```
Note: for some examples you will need to specify extra command line arguments to get useful results.
