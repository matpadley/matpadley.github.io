---
title: Github Advanced Security
layout: post
date: 2024-01-15
categories:
  - GitHub
tags: 
  - github
  - gitHub advanced security    # TAG names should always be lowercase
toc: true
---

## Introduction

GitHub Advanced Security is a facility within GitHub that will provide the following functionality to a repository:

* Dependency Management
* Code Security Review<
* Secret Scanning
    
This post is not designed to be a deep dive into the features, but a primer.

It is work noting that not all of the features are available in all of the repository tiers as GitHub Advanced Security is a paid service for all repositories except those that are public.

## Dependency Review

## Code Secutriy 

Code Security is a feature that will scan your code for any security vulnerabilities that match an issue from a CWE. When setting this feature up you can either use the default configuration:

* Scan the languages that Code Scanning detects in your repository
* Default query suite (ADD WHAT THIS MEANS)
* Scan on a pull request to the repository default branch (main, master, develop etc.)
* Scan on a pull request to any protected branch
* A weekly scan of the repository

The above settings can be mofified, to a certain extent, with the laguage that the Code Scanning runs against being able to be toggled on and off. The list of languages you can toggle are only the ones that Code Scanning itself has found. The only other setting that can be changed is the query suite that is used to scan the repository code base.

## Secret Scanning

This feature does precisley what it says on the tin and scans your repository for secrets. In addition it can stop a push which contains a recognised secret. 
