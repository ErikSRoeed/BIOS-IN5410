# BIOS-IN5410: Working with R 

> NB. I'm not going to stop you if you are curious, but the point of this repository is *not* to open, read, and "manually" interact with the files under `tutorials/`! Please follow the instructions below to show the student-facing content. The code files here are relatively complicated and you are most certainly not expected to understand them as part of the class. By all means ask how it works if you want to.

## Table of contents
- [Preparations before class](#preparations-before-class)
  - [1. Readings](#1-readings)
  - [2. Software](#2-software)
- [Summary of how to run the tutorials](#summary-of-how-to-run-the-tutorials)
- [Friday 2026.11.13](#friday-20261113)
  - [14.15 - 17.00: Programming with R](#1415---1700-programming-with-r)
- [Thursday 2026.11.19](#thursday-20261119)
  - [09.15 - 12.00: Data science with R](#0915---1200-data-science-with-r)
  - [13.15 - 16.00: Data visualisation with R](#1315---1600-data-visualisation-with-r)
- [Friday 2026.11.20](#friday-20261120)
  - [09.15 - 12.00: R on autopilot](#0915---1200-r-on-autopilot)
- [Resources and texts](#resources-and-texts)

## Preparations before class
### 1. Readings
Prior experience with programming (in R or otherwise) is not a formal entry requirement in BIOS-IN5410 and we will cover the basics in our first session. However, the less prior experience you have, the more you will benefit from diligent self-study (and the more you will struggle without it). Before class on Friday 2026.11.13 we highly advise you read *all* of https://rstudio-education.github.io/hopr/index.html (skip chapters 8, 10, and 12). You should make an effort to understand this book *before* class. If you have programming experience but have never touched R, this book will get you up to speed with R syntax.

### 2. Software
You must install all necessary software before class. We will not be able to spend time on this in plenary but can help you if you have problems with a *personal* laptop. If your laptop is owned by your university, see [University-managed laptops](#university-managed-laptops).

#### University-managed laptops
If you have a university-managed laptop, you might be able to install R and RStudio through a managed software portal (e.g. 'Managed Software Centre' on a UiO Mac). If you have difficulties installing R and RStudio on a university-managed machine, **consult your IT department**.

#### 2.1 R
You must install R before class (see instructions at https://www.r-project.org/). The Norwegian mirror is hosted by UiB: https://cran.uib.no/.

#### 2.2 RStudio
We will work with R through an 'IDE': an 'Integrated Development Environment'. This is a text editor with features that are helpful for programming, such as syntax highlighting and a built-in file browser. The IDE we will use is a classic R IDE, and is called 'RStudio'. Again, please install it *before* class. See https://docs.posit.co/ide/user/download.html.

#### 2.3 Clone or download this repository
Clone this repository with git:
```sh
git clone https://github.com/ErikSRoeed/BIOS-IN5410
```
To update your local copy of the repository later, use git again:
```sh
git fetch --all
git pull
```
If you don't have git on your local computer, simply download and unzip the repository (the green download button).

#### 2.4 Install the required packages
Run this from the **R terminal inside RStudio**:
```R
install.packages(c("learnr", "rmarkdown", "shiny", "knitr", "tidyverse"))
```

#### 2.5 Check that everything works
Open the BIOS-IN5410.Rproj RStudio project from your file tree or from within RStudio. Once you have done this, run the test tutorial and make sure every step works. If so, you are good to go for class! To run the tutorial, type the following in the RStudio R terminal:
```R
rmarkdown::run("tutorials/check_installation.Rmd")
```
Or, for illustration:

![A screenshot of typing the check_installation.Rmd call](assets/rstudio-console-run-check-installation.png)
This will open the tutorial in a new window:

![A screenshot of the check_installation tutorial](assets/check-installation-tutorial.png)

## Friday 2026.11.13
### 14.15 - 17.00: Programming with R
Today you will follow a self-paced (informal!) test covering the basic grammar of programming: variables, output, functions, loops, and conditional logic. Launch it with `rmarkdown::run("tutorials/programming.Rmd")`.

## Thursday 2026.11.19
### 09.15 - 10.00: Reproducible R
Set up a reproducible and version-controlled RStudio project and connect it to your GitHub account. Follow [this exercise](/documents/reproducibility.md).

### 10.00 - 10.15 Break
Stretch your legs, think about something else, get some fresh air, talk to someone you don't know ... whatever you do, try to give your brain some time off!

### 10.15 - 12.00: Writing and running scripts in R
You may have been taught R as an interactive statistical software before: running line by line in the console. But R is a programming language, and it is good practice to treat it this way: for reproducibility, proper standalone scripts are non-negotiable. Let's make some! Follow [this exercise](/documents/scripts.md)

### 12.00 - 13.15 Lunch break
Our usual midday lunch break.

## Further reading
- Garrett Grolemund, "Hands-On Programming With R" (https://rstudio-education.github.io/hopr/)
- Hadley Wickham, Mine Çetinkaya-Rundel, and Garrett Grolemund: "R for Data Science" 2nd ed. (https://r4ds.hadley.nz/)
- Claus O. Wilke: "Fundamentals of Data Visualization" (https://clauswilke.com/dataviz/)
