
![GitHub Actions Workflow Status](https://img.shields.io/github/actions/workflow/status/jadenzaleski/zhub/CI.yml?style=flat-square&logo=GitHub&label=CI)
![GitHub Actions Workflow Status](https://img.shields.io/github/actions/workflow/status/jadenzaleski/zhub/CD.yml?style=flat-square&logo=GitHub&label=CD)

![GitHub commits since latest release](https://img.shields.io/github/commits-since/jadenzaleski/zhub/latest?style=flat-square)


A nice place for all my applications to live and be tested.


# Installation

## Latest commit
To download the latest from the master branch:
```bash
curl -L -o zhub.zip https://github.com/jadenzaleski/zhub/archive/refs/heads/master.zip && unzip zhub.zip && mkdir zhub && cp -r zhub-master/* zhub && rm -rf zhub-master zhub.zip
```
This will download the latest version of zhub and extract it to a folder named `zhub`.

## Latest Release
...

## Latest Passing Build

# Workflow
All done with github actions.
CI runs on every push to master.
If CI passes, CD takes that and packages it up.
Will have one more workflow that will be dispatched manually to create an official release.

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
	n5 --- n6@{ shape: 'rounded', label: 'Deploy artifact' }
	n6 ---|'If MD'| n3@{ shape: 'rounded', label: 'Version & tag' }
	n3 --- n7@{ shape: 'rounded', label: 'Release' }
	end
	style n7 stroke:#00BF63,stroke-width:2px,fill:#00BF63,color:#000000
	style A stroke:#004AAD,stroke-width:2px
	style B stroke:#004AAD,stroke-width:2px
	linkStyle 1 stroke:#00BF63
```