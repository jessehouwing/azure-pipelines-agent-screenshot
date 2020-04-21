# Release Notes
> **15-04-2020**
> - First release

# Description

Ever wondered what your build agent was up to at a certain stage? this task takes a screenshot of your agents desktop. For me, this was especially useful while debugging a build that hung a Hosted Pool agent. [It helped me figure out why my build kept freezing up.](https://jessehouwing.net/what-to-do-when-your-build-hangs-on-the-hosted-pool/)

![Agent desktop](https://raw.githubusercontent.com/jessehouwing/azure-pipelines-agent-screenshot/master/extension/images/Screenshots/1st-screenshot.png?raw=true)

# Usage

```
steps:
- task: agent-screenshot@1
  condition: or(canceled(), failed())
```

You can download the logs from the build summary after the build completes.

![download logs](https://raw.githubusercontent.com/jessehouwing/azure-pipelines-agent-screenshot/master/extension/images/Screenshots/download-logs.png?raw=true)

Each screenshot is named acording to its location in the pipeline.

![screenshot in zip](https://raw.githubusercontent.com/jessehouwing/azure-pipelines-agent-screenshot/master/extension/images/Screenshots/screenshot-in-logs.png?raw=true)

If you like this extension, please leave a review and feedback. If you'd have suggestions or an issue, please [file an issue to give me a chance to fix it](https://github.com/jessehouwing/jessehouwing/azure-pipelines-agent-screenshot/issues).
