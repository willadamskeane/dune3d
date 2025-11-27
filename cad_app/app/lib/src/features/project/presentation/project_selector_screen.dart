import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../data/project_repository.dart';
import '../domain/project_entity.dart';

/// Provider for the project repository.
final projectRepositoryProvider = Provider<ProjectRepository>((ref) {
  return InMemoryProjectRepository();
});

/// Provider for the list of projects.
final projectListProvider = FutureProvider<List<ProjectEntity>>((ref) async {
  final repository = ref.watch(projectRepositoryProvider);
  return repository.listProjects();
});

/// Screen for selecting or creating projects.
class ProjectSelectorScreen extends ConsumerWidget {
  const ProjectSelectorScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final projectsAsync = ref.watch(projectListProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Projects'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () => context.goNamed('settings'),
          ),
        ],
      ),
      body: projectsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Text('Error loading projects: $error'),
        ),
        data: (projects) {
          if (projects.isEmpty) {
            return const Center(
              child: Text('No projects yet. Create one to get started!'),
            );
          }
          return ListView.builder(
            itemCount: projects.length,
            itemBuilder: (context, index) {
              final project = projects[index];
              return ListTile(
                title: Text(project.name),
                subtitle: Text('Updated: ${project.updatedAt}'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  // TODO: Set current project and navigate
                  context.goNamed('viewer');
                },
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'create_project',
        onPressed: () => _showCreateProjectDialog(context, ref),
        icon: const Icon(Icons.add),
        label: const Text('New Project'),
      ),
    );
  }

  void _showCreateProjectDialog(BuildContext context, WidgetRef ref) {
    final controller = TextEditingController();

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Create New Project'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: 'Project Name',
            hintText: 'Enter project name',
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              final name = controller.text.trim();
              if (name.isNotEmpty) {
                final repository = ref.read(projectRepositoryProvider);
                await repository.createProject(name);
                ref.invalidate(projectListProvider);
                if (dialogContext.mounted) {
                  Navigator.of(dialogContext).pop();
                  context.goNamed('viewer');
                }
              }
            },
            child: const Text('Create'),
          ),
        ],
      ),
    );
  }
}
