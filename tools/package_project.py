"""Package a Godot project with root-level project.godot and explicit directories."""

from pathlib import Path
import argparse
import zipfile


def package_project(project: Path, output: Path) -> int:
    excluded = {".godot", ".git", ".codegraph", "__pycache__"}
    paths = sorted(
        (
            path
            for path in project.rglob("*")
            if not excluded.intersection(path.relative_to(project).parts)
            and path.name != ".DS_Store"
            and path.resolve() != output.resolve()
        ),
        key=lambda path: path.relative_to(project).as_posix(),
    )
    output.parent.mkdir(parents=True, exist_ok=True)
    with zipfile.ZipFile(output, "w", zipfile.ZIP_DEFLATED) as archive:
        # Writing directories (including empty ones) before their children is
        # required by importers that do not create parents for each file.
        for path in paths:
            archive.write(path, path.relative_to(project).as_posix())

    with zipfile.ZipFile(output) as archive:
        names = set(archive.namelist())
        assert "project.godot" in names, "Project must be at the archive root"
        assert archive.testzip() is None, "Archive CRC verification failed"
        for entry in archive.infolist():
            for parent in Path(entry.filename).parents:
                if parent != Path("."):
                    assert parent.as_posix() + "/" in names, entry.filename
        return len(names)


def main() -> None:
    project = Path(__file__).resolve().parents[1]
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument(
        "output", nargs="?", type=Path,
        default=project.parent / "funny-battle-fork-spikes.zip",
    )
    args = parser.parse_args()
    count = package_project(project, args.output)
    print(f"Verified {count} entries: {args.output}")


if __name__ == "__main__":
    main()
