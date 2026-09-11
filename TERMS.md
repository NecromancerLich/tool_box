# Tool_Box Terms & Authorized-Use Conditions

**Terms version: 1**  
**Applies to: Tool_Box v1.01**

Tool_Box is a menu-driven wrapper for security, networking, system-administration, reconnaissance, enumeration, analysis, and related third-party tools.

Tool_Box was developed with substantial AI assistance ("vibe coded"). AI-assisted code may contain errors, incomplete validation, unsafe assumptions, or unexpected behavior. Review the source and test the project in a controlled environment before relying on it.

## Conditions of use

By selecting **Yes** at the Tool_Box version acknowledgement and continuing to use the program, you acknowledge the following:

1. **Authorized use only.** You will use Tool_Box only on systems, networks, services, accounts, applications, and data that you own or are explicitly authorized to access or test.

2. **You choose the target and command.** You are responsible for verifying targets, command options, privileges, credentials, timing, scope, and whether the activity is permitted.

3. **Security tools can cause harm.** Scans, enumeration, administrative utilities, exploit-development/testing tools, traffic-generation tools, and other commands may cause outages, lockouts, data loss, system changes, service degradation, credential exposure, or other unintended effects.

4. **As-is software.** Tool_Box is provided as-is and without warranties or guarantees. To the extent permitted by applicable law, the author(s) disclaim liability for claims, damages, losses, or other consequences arising from use, misuse, or inability to use Tool_Box.

5. **Third-party software.** Tool_Box invokes software maintained by other projects. Those programs retain their own licenses, documentation, risks, behavior, and support policies. Tool_Box does not warrant third-party software and inclusion does not imply affiliation, sponsorship, or endorsement.

6. **Credentials and sensitive data.** Tool_Box includes some redaction safeguards, but third-party commands may still display, store, transmit, or log sensitive values. You are responsible for protecting credentials, output, captures, reports, and configuration files.

7. **Review before execution.** You should review Command Preview, use Dry-Run where appropriate, and test new modules or changes in an isolated environment before using them on systems that matter.

8. **Compliance.** You are responsible for complying with applicable laws, contracts, acceptable-use policies, course/lab rules, employer policies, and any other restrictions that apply to the environment you are testing.

## Per-version acceptance record

Tool_Box stores the accepted terms version for the current Linux user in:

```text
~/.tool_box_terms.conf
```

The acceptance record is local. It is not telemetry and is not sent to the project author. Removing the file causes the acknowledgement to appear again. Tool_Box also records the accepted program version, so each new Tool_Box release asks for acknowledgement again; changing the terms version also forces a new acknowledgement.

## Relationship to the license

These conditions and notices do not replace the project's software license. Tool_Box is distributed under the MIT License; see `LICENSE`.

This document is provided for project disclosure and responsible-use guidance and is not legal advice. If enforceable contractual terms or legal protection are important for how you distribute or operate the project, obtain advice from a qualified attorney in the relevant jurisdiction.
