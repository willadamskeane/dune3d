import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;

import '../domain/project_entity.dart';
import 'project_repository.dart';
import 'project_serialization.dart';

/// File-based implementation of [ProjectRepository].
///
/// Stores projects as JSON files in the app's documents directory.
class FileProjectRepository implements ProjectRepository {
  final Directory _projectsDir;

  FileProjectRepository(this._projectsDir);

  /// Create a repository in the given base directory.
  factory FileProjectRepository.inDirectory(String basePath) {
    final dir = Directory(p.join(basePath, 'projects'));
    if (!dir.existsSync()) {
      dir.createSync(recursive: true);
    }
    return FileProjectRepository(dir);
  }

  String _projectFilePath(String id) {
    return p.join(_projectsDir.path, '$id.cadproj');
  }

  @override
  Future<ProjectEntity> createProject(String name) async {
    final now = DateTime.now();
    final id = now.microsecondsSinceEpoch.toString();

    final project = ProjectEntity(
      id: id,
      name: name,
      createdAt: now,
      updatedAt: now,
    );

    // Save initial project data
    final data = ProjectData(metadata: project);
    await _writeProjectFile(id, data.toJsonString());

    return project;
  }

  @override
  Future<void> deleteProject(String id) async {
    final file = File(_projectFilePath(id));
    if (await file.exists()) {
      await file.delete();
    }
  }

  @override
  Future<List<ProjectEntity>> listProjects() async {
    final projects = <ProjectEntity>[];

    if (!await _projectsDir.exists()) {
      return projects;
    }

    await for (final entity in _projectsDir.list()) {
      if (entity is File && entity.path.endsWith('.cadproj')) {
        try {
          final content = await entity.readAsString();
          final data = ProjectData.fromJsonString(content);
          projects.add(data.metadata);
        } catch (e) {
          debugPrint('Error reading project file: ${entity.path} - $e');
        }
      }
    }

    // Sort by updatedAt descending
    projects.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));

    return projects;
  }

  @override
  Future<ProjectEntity?> loadProject(String id) async {
    try {
      final content = await _readProjectFile(id);
      if (content == null) return null;

      final data = ProjectData.fromJsonString(content);
      return data.metadata;
    } catch (e) {
      debugPrint('Error loading project $id: $e');
      return null;
    }
  }

  @override
  Future<void> saveProject(ProjectEntity project) async {
    try {
      final existingContent = await _readProjectFile(project.id);

      ProjectData data;
      if (existingContent != null) {
        final existing = ProjectData.fromJsonString(existingContent);
        data = ProjectData(
          metadata: project.copyWith(updatedAt: DateTime.now()),
          sketchPoints: existing.sketchPoints,
          sketchSegments: existing.sketchSegments,
          sketchCircles: existing.sketchCircles,
          sketchArcs: existing.sketchArcs,
          sketchConstraints: existing.sketchConstraints,
          meshes: existing.meshes,
        );
      } else {
        data = ProjectData(
          metadata: project.copyWith(updatedAt: DateTime.now()),
        );
      }

      await _writeProjectFile(project.id, data.toJsonString());
    } catch (e) {
      debugPrint('Error saving project ${project.id}: $e');
      rethrow;
    }
  }

  /// Load complete project data including sketches and meshes.
  Future<ProjectData?> loadProjectData(String id) async {
    try {
      final content = await _readProjectFile(id);
      if (content == null) return null;

      return ProjectData.fromJsonString(content);
    } catch (e) {
      debugPrint('Error loading project data $id: $e');
      return null;
    }
  }

  /// Save complete project data.
  Future<void> saveProjectData(ProjectData data) async {
    try {
      final updatedData = ProjectData(
        metadata: data.metadata.copyWith(updatedAt: DateTime.now()),
        sketchPoints: data.sketchPoints,
        sketchSegments: data.sketchSegments,
        sketchCircles: data.sketchCircles,
        sketchArcs: data.sketchArcs,
        sketchConstraints: data.sketchConstraints,
        meshes: data.meshes,
      );

      await _writeProjectFile(data.metadata.id, updatedData.toJsonString());
    } catch (e) {
      debugPrint('Error saving project data: $e');
      rethrow;
    }
  }

  Future<String?> _readProjectFile(String id) async {
    final file = File(_projectFilePath(id));
    if (!await file.exists()) return null;
    return file.readAsString();
  }

  Future<void> _writeProjectFile(String id, String content) async {
    final file = File(_projectFilePath(id));
    await file.writeAsString(content);
  }

  /// Export project to a different location.
  Future<void> exportProject(String id, String exportPath) async {
    final content = await _readProjectFile(id);
    if (content == null) {
      throw Exception('Project not found: $id');
    }

    final exportFile = File(exportPath);
    await exportFile.writeAsString(content);
  }

  /// Import project from an external file.
  Future<ProjectEntity> importProject(String importPath) async {
    final file = File(importPath);
    if (!await file.exists()) {
      throw Exception('Import file not found: $importPath');
    }

    final content = await file.readAsString();
    final data = ProjectData.fromJsonString(content);

    // Create a new ID to avoid conflicts
    final newId = DateTime.now().microsecondsSinceEpoch.toString();
    final newMetadata = ProjectEntity(
      id: newId,
      name: '${data.metadata.name} (Imported)',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    final newData = ProjectData(
      metadata: newMetadata,
      sketchPoints: data.sketchPoints,
      sketchSegments: data.sketchSegments,
      sketchCircles: data.sketchCircles,
      sketchArcs: data.sketchArcs,
      sketchConstraints: data.sketchConstraints,
      meshes: data.meshes,
    );

    await _writeProjectFile(newId, newData.toJsonString());

    return newMetadata;
  }
}
