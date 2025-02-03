<p align="center"><img src="https://jadenzaleski.github.io/zhub/images/logo.png" alt="Image" width="200" height="200"></p>
<p align="center">
    <img src="https://img.shields.io/github/actions/workflow/status/jadenzaleski/zhub/CI.yml?style=flat-square&logo=GitHub&label=CI" alt="GitHub Actions Workflow Status">
    <img src="https://img.shields.io/github/actions/workflow/status/jadenzaleski/zhub/CD.yml?style=flat-square&logo=GitHub&label=CD" alt="GitHub Actions Workflow Status">
    <img src="https://img.shields.io/github/commits-since/jadenzaleski/zhub/latest?style=flat-square" alt="GitHub commits since latest release">
</p>
<h1 align="center">ZHub</h1>
<p align="center">A nice place for all my applications to live and be tested.</p>

# Requirements

# Installation
You can Find all the latest releases and builds on the ZHub [release & build](https://jadenzaleski.github.io/zhub/) page.


## Latest Release
To download the latest release of ZHub, you can use the following command:
```bash
mkdir -p zhub && curl -L https://jadenzaleski.github.io/zhub/downloads/latest/release | tar -xzv -C zhub
```

## Latest Passing Build
To download the latest passing build of ZHub, you can use the following command:
```bash
mkdir -p zhub && curl -L https://jadenzaleski.github.io/zhub/downloads/latest/build | tar -xzv -C zhub
```

## Install
Once Zhub has been downloaded and extracted, you can install it using the following command: 
```bash
./bin/install.sh
```
# Upgrade


# Workflow
```mermaid
---
title: ZHub Workflow
config:
    theme: dark
---
flowchart
	A@{ shape: 'stadium', label: 'Push to master' } --- s1
	subgraph s1['CI']
		n2
		n4@{ shape: 'rounded', label: 'Install ZHub' }
	end
	s1 ---|'If CI success'| n1
	n4
	n4 --- n2@{ shape: 'rounded', label: 'Run tests' }
	s1

	B@{ shape: 'stadium', label: 'Manual dispatch' } --- n1
	subgraph n1['CD']
		n6
		n5@{ shape: 'rounded', label: 'Package' }
	n5 --- n6@{ shape: 'rounded', label: 'Add artifacts' }
	n6 --- |If MD| n3@{ shape: 'rounded', label: 'Version & tag' }
	n3 --- n7@{ shape: 'rounded', label: 'Release' }
	n6 --- n8@{ shape: 'rounded', label: 'Deploy to gh-pages' }
	end
	style n7 stroke:#00BF63,stroke-width:2px,fill:#00BF63,color:#000000
	style A stroke:#004AAD,stroke-width:2px
	style B stroke:#004AAD,stroke-width:2px
	linkStyle 1 stroke:#00BF63
	style n8 fill:#00BF63,color:#000000,stroke:#00BF63
```