# Release Notes
> **15-04-2020**
> - First release

# Description

Ever wondered what your build agent was up to at a certain stage? this task takes a screenshot of your agents desktop. For me, this was especially useful while debugging a Hosted Pool agent. [It helped me figure out whe my build kept freezing up.](https://jessehouwing.net/what-to-do-when-your-build-hangs-on-the-hosted-pool/)

![extension/images/screenshots/1st-screenshot.png]

# Usage

```
steps:
- task: agent-screenshot@1
  condition: or(canceled(), failed())
```

If you like this extension, please leave a review and feedback. If you'd have suggestions or an issue, please [file an issue to give me a chance to fix it](https://github.com/jessehouwing/jessehouwing/azure-pipelines-agent-screenshot/issues).
