from ogdc_runner import argo


from hera.workflows import Steps, Workflow, script, models

@script(volume_mounts=[models.VolumeMount(name="qgnet-ogdc-workflow-pvc", mount_path="/mnt/")])
def writer():
    with open("/mnt/file.txt", "w+") as f:
        f.write("Hello, world!")

with Workflow(
    generate_name="hello-world-steps-",
    entrypoint="steps",
    workflows_service=argo.ARGO_WORKFLOW_SERVICE,
    volumes=[
        models.Volume(name="qgnet-ogdc-workflow-pvc", persistent_volume_claim={"claim_name": "qgnet-ogdc-workflow-pvc"})
    ],
) as w:
    with Steps(name="steps"):
        writer(name="write")


w.create()
