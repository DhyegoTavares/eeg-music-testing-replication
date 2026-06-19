## Replication Package - Executing Prophet Tool

In the `/replication` directory, you will find the zip file `prophet_eeg_study.zip` containing:

* **Tasks**: All stimuli presented to participants (`trialX_taskY.png` files, where X is the trial number (1–3) and Y is the task number (1–4)).  
* **Baseline images**: Reference images used for baseline conditions (`relax.png` and `+.png`).  
* **2 executable JAR files**: The experiment-viewer and experiment-editor, along with the corresponding `.xml` configuration file used to create the tasks.  
   * You need to have Java installed.  
   * To **replicate the experiment**, simply open the executable JAR file `experiment-viewer.jar`. This will load the default configuration used in the study.  
   * To **customize the experiment**, open the editor (`experiment-editor.jar`).  
   * Make sure that the tasks (`.png` images), the `.jar` files, and the `.xml` file are all located in the same folder.  
* For more details on how to use the Prophet tool, please refer to the official repository: [Prophet GitHub](https://github.com/feigensp/Prophet).
