

    @Override
    public BidScoreVo queryByTkbm(BidScoreQuery scoreQuery) {
        Long projectId = projectService.findProjectIdByBdhBjbhZbid(scoreQuery.getBjbh(), scoreQuery.getBdh(), scoreQuery.getZbid());
        if (projectId == null || projectId <= 0) {
            throw new RuntimeException("项目不存在");
        }
        EvaluationClause queryTkbm = new EvaluationClause();
        queryTkbm.setClauseCode(scoreQuery.getTkbm());
        EvaluationResult evaluationResult = evaluationResultService.selectEvaluationResultList(params).stream().findFirst().orElse(null);
        return null;
    }
dfafasfdfafdsfsf

    public JGBAjaxResult queryStatus(@RequestBody BidQueryStatus queryStatus) {
        JGBAjaxResult valid = validateBaseParams(queryStatus.getBdh(), queryStatus.getBjbh(), queryStatus.getZbid());
        if (valid != null) {
            return valid;
        }
        dfasfsaffdsaf

        BidStatusVo vo = bidExternalInterfaceService.queryStatus(queryStatus);
        return successOrFail(vo);
    }

    @Override
    public BidScoreDetailVo query(BidScoreQuery scoreQuery) {
        Long projectId = projectService.findProjectIdByBdhBjbhZbid(scoreQuery.getBjbh(), scoreQuery.getBdh(), scoreQuery.getZbid());
        if (projectId == null || projectId <= 0) {
            throw new RuntimeException("项目不存在");
        }


        sdfafasfsfd
        List<ScoreDetail> scoreDetails = evaluationResultService.selectScoreDetailListByProjectId(projectId);
        BidScoreDetailVo detailVo = new BidScoreDetailVo();
        BeanUtils.copyProperties(scoreQuery, detailVo);
        detailVo.setScoreDetails(scoreDetails);
        detailVo.setTimestamp(DateUtils.getNowDate().getTime());
        return detailVo;
    }
