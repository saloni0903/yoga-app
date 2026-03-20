using Microsoft.AspNetCore.Mvc;
using yesmain.DTOs;
using yesmain.Models;

public interface IGroupServices
{
    Task<GroupResponseDto> CreateGroupAsync(GroupRequestDto dto);
    Task<JoinGroupResponseDto> JoinGroupAsync(Guid groupId);

    Task<bool> DeleteAsync(Guid groupId);
    Task<GroupResponseDto> GetByIdAsync(Guid groupId);
    Task<List<GroupDto>> GetGroupsAsync(GroupFilterDto filter);

    Task<List<GroupMemberResponseDto>> GetGroupMemberAsync(Guid groupId);
    Task<List<GroupResponseDto>> GetMyGroupsAsync();
    Task<bool> LeaveAsync(Guid groupId);
    Task<UpdateGroupResDto> UpdateAsync(Guid groupId,UpdateGroupReqDto dto);
}
